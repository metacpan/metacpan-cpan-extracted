{
                 "Type" : "AWS::ElasticLoadBalancing::LoadBalancer",
                 "Properties" : {
                     "AvailabilityZones" : [ "us-east-1a" ],
                     "Listeners" : [ {
                         "LoadBalancerPort" : "80",
                         "InstancePort" : "80",
                         "Protocol" : "HTTP"
                     } ]
                 }
             }
