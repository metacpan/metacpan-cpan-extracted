{
      "Type": "AWS::EC2::SecurityGroupEgress",
      "Properties": {
        "GroupId": { "Ref": "SGBase" },
        "IpProtocol": "tcp",
        "FromPort": "80",
        "ToPort": "80",
        "DestinationSecurityGroupId": { "Ref": "SGBase" }
      }
    }
