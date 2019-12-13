{
        "Type": "AWS::ApiGatewayV2::Authorizer",
        "Properties": {
            "Name": "LambdaAuthorizer",
            "ApiId": {
                "Ref": "MyApi"
            },
            "AuthorizerType": "REQUEST",
            "AuthorizerCredentialsArn": "Arn",
            "AuthorizerUri": {
                "Fn::Join": [
                    "",
                    [
                        "arn:",
                        {
                            "Ref": "AWS::Partition"
                        },
                        ":apigateway:",
                        {
                            "Ref": "AWS::Region"
                        },
                        ":lambda:path/2015-03-31/functions/",
                        "/invocations"
                    ]
                ]
            },
            "AuthorizerResultTtlInSeconds": 500,
            "IdentitySource": [
                "route.request.header.Auth"
            ]
        }
    }
