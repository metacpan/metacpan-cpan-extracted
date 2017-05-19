{
   "Type" : "AWS::AutoScaling::Trigger",
   "Properties" : {
      "MetricName" : "CPUUtilization",
      "Namespace" : "AWS/EC2",
      "Statistic" : "Average",
      "Period" : "300",
      "UpperBreachScaleIncrement" : "1",
      "LowerBreachScaleIncrement" : "-1",
      "AutoScalingGroupName" : { "Ref" : "MyServerGroup" },
      "BreachDuration" : "600",
      "UpperThreshold" : "90",
      "LowerThreshold" : "75",
      "Dimensions" : [ {
         "Name" : "AutoScalingGroupName",
         "Value" : { "Ref" : "MyServerGroup" }
      } ]
   }
}
