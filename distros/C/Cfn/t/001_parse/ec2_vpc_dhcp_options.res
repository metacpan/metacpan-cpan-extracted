{
         "Type" : "AWS::EC2::VPCDHCPOptionsAssociation",
         "Properties" : {
             "VpcId" : {"Ref" : "myNetworkAcl"},
             "DhcpOptionsId" : {"Ref" : "myDhcpOption"}
         }
      }
