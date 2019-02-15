{
 "Type" : "AWS::EC2::SecurityGroup",
 "Properties" : {
     "GroupDescription" : "allow connections from specified CIDR ranges",
     "SecurityGroupIngress" : [
         {
             "IpProtocol" : "tcp",
             "FromPort" : "80",
             "ToPort" : "80",
             "CidrIp" : "0.0.0.0/0"
         },{
             "IpProtocol" : "tcp",
             "FromPort" : "22",
             "ToPort" : "22",
             "CidrIp" : "192.168.1.1/32"
         }
     ]
 }
}
