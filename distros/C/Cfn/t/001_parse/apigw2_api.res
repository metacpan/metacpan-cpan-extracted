{
      "Type": "AWS::ApiGatewayV2::Api",
      "Properties": {
        "Name": "MyApi",
        "ProtocolType": "WEBSOCKET",
        "RouteSelectionExpression": "$request.body.action",
        "ApiKeySelectionExpression": "$request.header.x-api-key"
      }
   }
