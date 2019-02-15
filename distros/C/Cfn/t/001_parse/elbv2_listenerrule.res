{
  "Type": "AWS::ElasticLoadBalancingV2::ListenerRule",
  "Properties": {
    "Actions": [{
      "Type": "forward",
      "TargetGroupArn": { "Ref": "TargetGroup" }
    }],
    "Conditions": [{
      "Field": "path-pattern",
      "Values": [ "/img/*" ]
    }],
    "ListenerArn": { "Ref": "Listener" },
    "Priority": 1
  }
}
