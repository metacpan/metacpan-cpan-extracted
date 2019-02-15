{
         "Type" : "AWS::EC2::EIPAssociation",
         "Properties" : {
             "InstanceId" : { "Ref" : "logical name of an AWS::EC2::Instance resource" },
             "AllocationId" : "existing VPC Elastic IP allocation ID"
         }
     }
