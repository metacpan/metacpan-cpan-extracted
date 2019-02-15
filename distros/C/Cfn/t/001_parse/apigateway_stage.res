{
  "Type": "AWS::ApiGateway::Stage",
  "Properties": {
    "StageName": "Prod",
    "Description": "Prod Stage",
    "RestApiId": { "Ref": "MyRestApi" },
    "DeploymentId": { "Ref": "TestDeployment" },
    "ClientCertificateId": { "Ref": "ClientCertificate" },
    "Variables": { "Stack": "Prod" },
    "MethodSettings": [{
      "ResourcePath": "/",
      "HttpMethod": "GET",
      "MetricsEnabled": "true",
      "DataTraceEnabled": "true"
    }, {
      "ResourcePath": "/stack",
      "HttpMethod": "POST",
      "MetricsEnabled": "true",
      "DataTraceEnabled": "true",
      "ThrottlingBurstLimit": "999"
    }, {
      "ResourcePath": "/stack",
      "HttpMethod": "GET",
      "MetricsEnabled": "true",
      "DataTraceEnabled": "true",
      "ThrottlingBurstLimit": "555"
    }]
  }
}
