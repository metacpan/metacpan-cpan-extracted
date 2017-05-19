{
      "Type" : "AWS::EC2::SecurityGroup",
      "Properties" : {
        "GroupDescription" : "HTTP and SSH access",
        "SecurityGroupIngress" : [ {
          "IpProtocol" : "tcp", 
          "FromPort" : "22", "ToPort" : "22", 
          "CidrIp" : { "Ref" : "SSHFrom" }
        } ]
      }
    }
