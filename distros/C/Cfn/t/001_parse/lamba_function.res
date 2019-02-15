{
  "Type": "AWS::Lambda::Function",
  "Properties": {
    "Code": {
      "ZipFile":  {"Fn::Join": ["\n", [
        "var aws  = require('aws-sdk');",
        "var config = new aws.ConfigService();",
        "var ec2 = new aws.EC2();",

        "exports.handler = function(event, context) {",
        "    compliance = evaluateCompliance(event, function(compliance, event) {",
        "        var configurationItem = JSON.parse(event.invokingEvent).configurationItem;",

        "        var putEvaluationsRequest = {",
        "            Evaluations: [{",
        "                ComplianceResourceType: configurationItem.resourceType,",
        "                ComplianceResourceId: configurationItem.resourceId,",
        "                ComplianceType: compliance,",
        "                OrderingTimestamp: configurationItem.configurationItemCaptureTime",
        "            }],",
        "            ResultToken: event.resultToken",
        "        };",

        "        config.putEvaluations(putEvaluationsRequest, function(err, data) {",
        "            if (err) context.fail(err);",
        "            else context.succeed(data);",
        "        });",
        "    });",
        "};",

        "function evaluateCompliance(event, doReturn) {",
        "    var configurationItem = JSON.parse(event.invokingEvent).configurationItem;",
        "    var status = configurationItem.configurationItemStatus;",
        "    if (configurationItem.resourceType !== 'AWS::EC2::Volume' || event.eventLeftScope || (status !== 'OK' && status !== 'ResourceDiscovered'))",
        "        doReturn('NOT_APPLICABLE', event);",
        "    else ec2.describeVolumeAttribute({VolumeId: configurationItem.resourceId, Attribute: 'autoEnableIO'}, function(err, data) {",
        "        if (err) context.fail(err);",
        "        else if (data.AutoEnableIO.Value) doReturn('COMPLIANT', event);",
        "        else doReturn('NON_COMPLIANT', event);",
        "    });",
        "}"
      ]]}
    },
    "Handler": "index.handler",
    "Runtime": "nodejs4.3",
    "Timeout": "30",
    "Role": {"Fn::GetAtt": ["LambdaExecutionRole", "Arn"]}
  }
}
