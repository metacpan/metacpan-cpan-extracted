{
  "Type": "AWS::IAM::Policy",
  "Properties": {
    "PolicyDocument": {
      "Statement": [{
        "Action": [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ],
        "Effect": "Allow",
        "Resource": [{
          "Fn::Join": [ "", [
              "arn:aws:s3:::", {
                "Ref": "RecordServiceS3Bucket"
              }
            ]
          ]
        }]
      },{
        "Action": [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl"
        ],
        "Effect": "Allow",
        "Resource": [{
          "Fn::Join": [ "", [
              "arn:aws:s3:::", {
                "Ref": "RecordServiceS3Bucket"
              },
              "/*"
            ]
          ]
        }]
      }, {
        "Action": [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ],
        "Effect": "Allow",
        "Resource": [{
          "Fn::Join": [ "", [ 
             "arn:aws:s3:::", {
               "Fn::Join": [ "-", [ 
                 { "Ref": "AWS::Region" }, 
                 { "Ref": "AWS::StackName" }, 
                 "replicationbucket"
               ]]
             }, 
             "/*"
          ]]
        }]
      }]
    },
    "PolicyName": "BucketBackupPolicy",
    "Roles": [{
      "Ref": "WorkItemBucketBackupRole"
    }]
  }
}
