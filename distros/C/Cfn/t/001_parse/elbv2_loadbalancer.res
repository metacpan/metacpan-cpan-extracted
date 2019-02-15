 {
  "Type": "AWS::ElasticLoadBalancingV2::LoadBalancer",
  "Properties": {
    "Scheme" : "internal",
    "Subnets" : [ {"Ref": "SubnetAZ1"}, {"Ref" : "SubnetAZ2"}],
    "LoadBalancerAttributes" : [
      { "Key" : "idle_timeout.timeout_seconds", "Value" : "50" }
    ],
    "SecurityGroups": [{"Ref": "SecurityGroup1"}, {"Ref" : "SecurityGroup2"}],
    "Tags" : [
      { "Key" : "key", "Value" : "value" },
      { "Key" : "key2", "Value" : "value2" }
    ]
  }
}
