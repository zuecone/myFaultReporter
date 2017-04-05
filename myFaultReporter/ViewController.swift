//
//  ViewController.swift
//  myFaultReporter
//
//  Created by Henry McC on 2017/03/30.
//  Copyright © 2017 HiddenPlatform. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    
    
    @IBOutlet weak var crosshair: UIImageView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var imgHolder: UIImageView!
    @IBOutlet weak var borderImg: UIImageView!
    
    @IBOutlet weak var typePckr: UIPickerView!
    
    var pickerDataOne = [""]
    
    let locationManager = CLLocationManager()
    var mapHasCentredOnce = false
    var geoFire: GeoFire!
    var geoFireRef: FIRDatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        typePckr.delegate = self
        typePckr.dataSource = self
        
        //this will keep track of the user
        populatePickers()
        getSegmentIndex()
        mapView.userTrackingMode = MKUserTrackingMode.follow
        
        //crosshair.alpha = 0
        geoFireRef = FIRDatabase.database().reference()
        geoFire = GeoFire(firebaseRef: geoFireRef)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        locationAuthStatus()
    }
    
    
    //////////////Authorization
    func locationAuthStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse{
            mapView.showsUserLocation = true
        }else{
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            mapView.showsUserLocation = true
        }
    }
    
    
    
    func centerMapOnLocation(location: CLLocation){
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 150, 150)
        mapView.setRegion(coordinateRegion, animated: true)
        
    }
    
    
    //One time use so first load of map and centred location.
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if let loc = userLocation.location {
            if !mapHasCentredOnce {
                centerMapOnLocation(location: loc)
                showSightingsOnMap(location: loc)
                crosshair.center = CGPoint(x: imgHolder.frame.width/2, y: imgHolder.frame.height/2 + borderImg.frame.height + 35)
//                activityIndicator.center = CGPointMake(view.width/2, view.height/2)
                mapHasCentredOnce = true
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView: MKAnnotationView?
        let annoIdentifier = "Pokemon"
        
        
        
        if annotation.isKind(of: MKUserLocation.self){
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "User")
            annotationView?.image = UIImage(named: "person")
            

        }else if let deqAnno = mapView.dequeueReusableAnnotationView(withIdentifier: annoIdentifier) {
            annotationView = deqAnno
            annotationView?.annotation = annotation
        }else {
            let av = MKAnnotationView(annotation: annotation, reuseIdentifier: annoIdentifier)
            av.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            annotationView = av
        }
        
        if let annotationView = annotationView, let anno = annotation as? PokeAnnotation {
            annotationView.canShowCallout = true
            annotationView.image = UIImage(named: "\(anno.pokemonNumber)")
            let btn = UIButton()
            btn.frame = CGRect(x: 0, y: 0, width: 30, height: 30) //image size
            btn.setImage(UIImage(named: "map"), for: .normal)
            annotationView.rightCalloutAccessoryView = btn
        }
        
        return annotationView
    }
    
    
    func createSighting(forLocation location: CLLocation, withPokemon pokeId: Int){
        
        geoFire.setLocation(location, forKey: "\(pokeId)")
    }
    
    func showSightingsOnMap(location: CLLocation){
        let circleQuery = geoFire!.query(at: location, withRadius: 2.5)
        
        _ = circleQuery?.observe(GFEventType.keyEntered, with: { (key, location) in
            if let key = key, let location = location {
                let anno = PokeAnnotation(coordinate: location.coordinate, pokemonNumber: Int(key)!)
                self.mapView.addAnnotation(anno)
            }
        })
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        crosshair.alpha = CGFloat(0.25)
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        showSightingsOnMap(location: loc)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        crosshair.alpha = 0
        var center = mapView.centerCoordinate
        
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let anno = view.annotation as? PokeAnnotation {
            let place = MKPlacemark(coordinate: anno.coordinate)
            let destination = MKMapItem(placemark: place)
            destination.name = "Reported Fault" ////CHANGE THIS TO WHATEVER IS SAVED IN Firebase
            let regionDistance: CLLocationDistance = 1000
            let regionSpan = MKCoordinateRegionMakeWithDistance(anno.coordinate, regionDistance, regionDistance)
            
            let option = [MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving] as [String: Any]
            MKMapItem.openMaps(with: [destination], launchOptions: option)
        }
    }
   
    
    
    
    //Set up the picker delegate and datasource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataOne.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerDataOne[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        //call the function that will manage the selection
    }
    
    
    func populatePickers(){
     
    }
    
    func getSegmentIndex(){
        switch segmentedControl.selectedSegmentIndex
        {
        case 0:
            pickerDataOne = ["Theft","Vandalism","Graffiti"]
            typePckr.selectRow(0, inComponent: 0, animated: true)
            typePckr.reloadAllComponents()
        case 1:
            pickerDataOne = ["Pothole","Traffic Lights","Burst Pipe"]
            typePckr.selectRow(0, inComponent: 0, animated: true)
            typePckr.reloadAllComponents()
        default:
            break;
        }
    }
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!

    @IBAction func indexChanged(_ sender: UISegmentedControl) {
        getSegmentIndex()
        
    }
    
    
    @IBAction func submitCurrentLocation(_ sender: Any) {
        let location = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        
        let rand = arc4random_uniform(20) + 1
        createSighting(forLocation: location, withPokemon: Int(rand))
        showSightingsOnMap(location: location)

    }
}

