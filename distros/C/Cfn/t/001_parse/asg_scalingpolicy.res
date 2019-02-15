{
  "Type" : "AWS::AutoScaling::ScalingPolicy",
  "Properties" : {
    "AdjustmentType" : "ChangeInCapacity",
    "PolicyType" : "SimpleScaling", 
    "Cooldown" : "60",
    "AutoScalingGroupName" : { "Ref" : "ASG" },
    "ScalingAdjustment" : 1
  }
}
