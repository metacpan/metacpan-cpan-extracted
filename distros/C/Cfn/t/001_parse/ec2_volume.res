{
 "Type" : "AWS::EC2::Volume",
 "Properties" : {
     "Size" : 120,
     "SnapshotId" : "specify a SnapShotId if no Size",
     "AvailabilityZone" : { "Ref" : "AvailabilityZone" }
 }
}
