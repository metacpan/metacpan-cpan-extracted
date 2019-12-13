{
    "Type": "AWS::ApiGatewayV2::Api",
    "Properties": {
        "Name": "Lambda Proxy",
        "Description": "Lambda proxy using quick create",
        "ProtocolType": "HTTP",
        "Target": "arn:aws:apigateway:{region}:lambda:path/2015-03-31/functions/arn:aws:lambda:{region}:{account-id}:function:{function-name}/invocations"
     }
}
