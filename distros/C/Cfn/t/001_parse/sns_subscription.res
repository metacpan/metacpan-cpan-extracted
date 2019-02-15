{
  "Type" : "AWS::SNS::Subscription",
  "Properties" : {
    "Endpoint" : "test@email.com",
    "Protocol" : "email",
    "TopicArn" : {"Ref" : "MySNSTopic"}
  }
}
