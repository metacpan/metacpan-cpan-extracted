{
    "Type": "AWS::EC2::SubnetCidrBlock",
    "Properties": {
      "Ipv6CidrBlock": { "Ref" : "Ipv6SubnetCidrBlock" },
      "SubnetId": { "Ref" : "Ipv6TestSubnet" }
    }
  }
