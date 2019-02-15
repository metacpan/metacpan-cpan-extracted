{
  "Type": "AWS::IAM::Role",
  "Properties": {
    "AssumeRolePolicyDocument": {
      "Statement": [{
        "Action": [ "sts:AssumeRole" ],
        "Effect": "Allow",
        "Principal": {
          "Service": [ "s3.amazonaws.com" ]
        }
      }]
    }
  }    
}
