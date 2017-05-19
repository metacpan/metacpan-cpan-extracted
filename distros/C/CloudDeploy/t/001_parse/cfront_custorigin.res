{
   "Type" : "AWS::CloudFront::Distribution",
   "Properties" : {
      "DistributionConfig" : {
         "Origins" : {
            "DomainName" : "www.example.com",
            "Id" : "myCustomOrigin",
            "CustomOriginConfig" : {
               "HTTPPort" : "80",
               "HTTPSPort" : "443",
               "OriginProtocolPolicy" : "http-only"
            }
         },
         "Enabled" : "true",
         "Comment" : "Some comment",
         "DefaultRootObject" : "index.html",
         "Logging" : {
            "Bucket" : "mylogs.s3.amazonaws.com",
            "Prefix" : "myprefix"
         },
         "Aliases" : [ "mysite.example.com", "yoursite.example.com" ],
         "DefaultCacheBehavior" : {
             "TargetOriginId" : "myCustomOrigin",
             "ForwardedValues" : {
                 "QueryString" : "false"
             },
             "TrustedSigners" : [ "1234567890EX", "1234567891EX" ],
             "ViewerProtocolPolicy" : "allow-all"
         }
      }
   }
}
