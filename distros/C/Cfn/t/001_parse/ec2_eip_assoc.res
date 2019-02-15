{
         "Type" : "AWS::EC2::EIPAssociation",
         "Properties" : {
             "InstanceId" : { "Ref" : "logical name of an AWS::EC2::Instance resource" },
             "EIP" : "existing Elastic IP address"
         }
     }
