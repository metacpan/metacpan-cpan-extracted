{
  "Type": "AWS::OpsWorks::UserProfile",
  "Properties": {
    "IamUserArn": {
      "Fn::GetAtt": ["testUser", "Arn"]
    },
    "AllowSelfManagement": "true",
    "SshPublicKey": "xyz1234567890"
  }
}
