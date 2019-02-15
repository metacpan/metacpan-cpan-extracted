{
  "Type": "AWS::Lambda::Permission",
  "Properties": {
    "FunctionName" : { "Fn::GetAtt" : ["MyLambdaFunction", "Arn"] },
    "Action": "lambda:InvokeFunction",
    "Principal": "s3.amazonaws.com",
    "SourceAccount": { "Ref" : "AWS::AccountId" }
  }
}
