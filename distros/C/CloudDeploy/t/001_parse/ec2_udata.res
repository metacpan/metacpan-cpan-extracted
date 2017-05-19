{
      "Type" : "AWS::EC2::Instance",
      "Properties" : {
        "ImageId" : { "Fn::FindInMap" : [ "RegionMap", { "Ref" : "AWS::Region" }, "AMI" ]},
        "KeyName" : { "Ref" : "KeyName" },
        "NetworkInterfaces" : [ { "NetworkInterfaceId" : {"Ref" : "controlXface"}, "DeviceIndex" : "0" } ],
        "Tags" : [ {"Key" : "Role", "Value" : "Test Instance"}],
        "UserData" : { "Fn::Base64" : { "Ref" : "WebServerPort" }}
      }
    }
