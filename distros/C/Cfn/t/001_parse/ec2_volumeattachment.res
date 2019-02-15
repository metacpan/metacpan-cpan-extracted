{
   "Type" : "AWS::EC2::VolumeAttachment",
   "Properties" : {
     "InstanceId" : { "Ref" : "Ec2Instance" },
     "VolumeId"  : { "Ref" : "NewVolume" },
     "Device" : "/dev/sdh"
   }
 }
