{
 "Type" : "AWS::EC2::Instance",
 "Properties" : {
     "KeyName" : { "Ref" : "KeyName" },
     "SecurityGroups" : [ {
         "Ref" : "logical name of AWS::EC2::SecurityGroup resource"
     } ],
     "UserData" : {
         "Fn::Base64" : {
             "Fn::Join" : [ ":", [
                 "PORT=80",
                 "TOPIC=", {
                     "Ref" : "logical name of an AWS::SNS::Topic resource"
                 },
                 "ACCESS_KEY=", { "Ref" : "AccessKey" },
                 "SECRET_KEY=", { "Ref" : "SecretKey" } ]
             ]
         }
      },
     "InstanceType" : "m1.small",
     "AvailabilityZone" : "us-east-1a",
     "ImageId" : "ami-1e817677",
     "Volumes" : [
        { "VolumeId" : {
             "Ref" : "logical name of AWS::EC2::Volume resource"
        },
        "Device" : "/dev/sdk" }
     ],

     "Tags" : [ {
         "Key" : "Name",
         "Value" : "MyTag"
     } ]
 }
}
