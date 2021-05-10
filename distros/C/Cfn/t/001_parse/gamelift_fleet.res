{
  "Type": "AWS::GameLift::Fleet",
  "Properties": {
    "Name": "MyGameFleet",
    "Description": "A fleet for my game",
    "BuildId": { "Ref": "BuildResource" },
    "RuntimeConfiguration": {
      "ServerProcesses": [
        {
          "ConcurrentExecutions": "1",
          "LaunchPath": "c:\\game\\TestApplicationServer.exe"
        }
      ]
    },
    "EC2InstanceType": "t2.small",
    "DesiredEC2Instances": "2",
    "EC2InboundPermissions": [
      {
        "FromPort": "1234",
        "ToPort": "1324",
        "IpRange": "0.0.0.0/24",
        "Protocol": "TCP"
      },
      {
        "FromPort": "1356",
        "ToPort": "1578",
        "IpRange": "192.168.0.0/24",
        "Protocol": "UDP"
      }
    ]
  }
}
