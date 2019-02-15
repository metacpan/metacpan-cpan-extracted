{
   "Type" : "AWS::EC2::Volume",
   "Properties" : {
     "Size" : "100",
     "AvailabilityZone" : { "Fn::GetAtt" : [ "Ec2Instance", "AvailabilityZone" ]}
   }
 }
