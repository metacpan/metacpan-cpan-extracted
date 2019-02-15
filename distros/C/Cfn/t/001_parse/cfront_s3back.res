{
   "Type" : "AWS::CloudFront::Distribution",
   "Properties" : {
      "DistributionConfig" : {
          "Origins" : [ {
              "DomainName": "mybucket.s3.amazonaws.com",
              "Id" : "myS3Origin",
              "S3OriginConfig" : {
                  "OriginAccessIdentity" : "origin-access-identity/cloudfront/E127EXAMPLE51Z"
              }
          }],
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
              "TrustedSigners" : [ "1234567890EX", "1234567891EX" ],
              "ViewerProtocolPolicy" : "allow-all"
          }
      }
   }
 } 
