{
            "Type" : "AWS::CloudFront::Distribution",
            "Properties" : {
               "DistributionConfig" : {
                   "Origins" : [ {
                           "Id" : "myS3Origin",
                           "DomainName" : "mybucket.s3.amazonaws.com",
                           "S3OriginConfig" : {
                               "OriginAccessIdentity" : "origin-access-identity/cloudfront/E127EXAMPLE51Z"
                           }
                       }, 
                       {
                           "Id" : "myCustomOrigin",
                           "DomainName" : "www.example.com",
                           "CustomOriginConfig" : {
                               "HTTPPort" : "80",
                               "HTTPSPort" : "443",
                               "OriginProtocolPolicy" : "http-only"
                           }
                       }
                   ],
                   "Enabled" : "true",
                   "Comment" : "Some comment",
                   "DefaultRootObject" : "index.html", 
                   "Logging" : {
                       "Bucket" : "mylogs.s3.amazonaws.com",
                       "Prefix" : "myprefix"
                   },            
                   "Aliases" : [ "mysite.example.com", "yoursite.example.com" ],
                   "DefaultCacheBehavior" : {
                       "TargetOriginId" : "myS3Origin",
                       "ForwardedValues" : {
                           "QueryString" : "false"
                        },
                       "TrustedSigners" : [ "1234567890EX", "1234567891EX"  ],
                       "ViewerProtocolPolicy" : "allow-all",
                       "MinTTL" : "100"
                   },
                   "CacheBehaviors" : [ {
                            "TargetOriginId" : "myS3Origin",
                            "ForwardedValues" : {
                                "QueryString" : "true"
                            },
                            "TrustedSigners" : [ "1234567890EX", "1234567891EX" ],
                            "ViewerProtocolPolicy" : "allow-all",
                            "MinTTL" : "50",
                            "PathPattern" : "images1/*.jpg"
                        }, 
                        {
                            "TargetOriginId" : "myCustomOrigin",
                            "ForwardedValues" : {
                                "QueryString" : "true"
                            },
                            "TrustedSigners" : [ "1234567890EX", "1234567891EX"  ],
                            "ViewerProtocolPolicy" : "allow-all",
                            "MinTTL" : "50",
                            "PathPattern" : "images2/*.jpg"
                        }
                   ]
                }
            }
        }
