{
        "Type": "AWS::ApiGatewayV2::Integration",
        "Properties": {
            "ApiId": {
                "Ref": "MyApi"
            },
            "Description": "Lambda Integration",
            "IntegrationType": "AWS",
            "IntegrationUri": {
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
                        {
                            "Ref": "MyLambdaFunction"
                        },
                        "/invocations"
                    ]
                ]
            },
            "CredentialsArn": "MyCredentialsArn",
            "IntegrationMethod": "GET",
            "ConnectionType": "INTERNET"
        }
    }
