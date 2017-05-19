{
   "Type" : "AWS::AutoScaling::AutoScalingGroup",
   "Properties" : {
      "AvailabilityZones" : { "Ref" : "azList" },
      "LaunchConfigurationName" : { "Ref" : "myLCOne" },
      "MinSize" : "0",
      "MaxSize" : "2",
      "DesiredCapacity" : "1",
      "NotificationConfigurations" : [ {
         "TopicARN" : { "Ref" : "topic1" },
         "NotificationTypes" : [
            "autoscaling:EC2_INSTANCE_LAUNCH",
            "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
            "autoscaling:EC2_INSTANCE_TERMINATE",
            "autoscaling:EC2_INSTANCE_TERMINATE_ERROR"
         ]
      } ]
   }
}
