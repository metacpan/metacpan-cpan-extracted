{
  "Type": "AWS::ApiGateway::Method",
  "Properties": {
    "RestApiId": {"Ref":"LambdaSimpleProxy"},
    "ResourceId": {"Ref":"ProxyResource"},
    "HttpMethod": "ANY",
    "AuthorizationType": "NONE",
    "Integration": {
      "Type": "AWS_PROXY",
      "IntegrationHttpMethod": "POST",
      "Uri": { "Fn::Sub":"arn:aws:apigateway:${AWS::Region}:lambda:path/2015-03-31/functions/${LambdaForSimpleProxy.Arn}/invocations"}
    }
  }
}
