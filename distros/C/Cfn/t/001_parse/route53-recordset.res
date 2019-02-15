{
      "Type" : "AWS::Route53::RecordSet",
      "Properties" : {
         "HostedZoneName" : {
            "Fn::Join" : [ "", [
               { "Ref" : "HostedZone" }, "."
            ] ]
         },
         "Comment" : "DNS name for my instance.",
         "Name" : {
            "Fn::Join" : [ "", [
               {"Ref" : "Ec2Instance"}, ".",
               {"Ref" : "AWS::Region"}, ".",
               {"Ref" : "HostedZone"} ,"."
            ] ]
         },
         "Type" : "A",
         "TTL" : "900",
         "ResourceRecords" : [
            { "Fn::GetAtt" : [ "Ec2Instance", "PublicIp" ] }
         ]
      }
   }
