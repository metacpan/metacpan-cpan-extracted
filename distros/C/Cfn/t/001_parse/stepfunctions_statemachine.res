{
          "Type": "AWS::StepFunctions::StateMachine",
             "Properties": {
                "DefinitionString": {
                   "Fn::Join": [
                      "\n",
                      [
                         "{",
                         "    \"StartAt\": \"HelloWorld\",",
                         "    \"States\" : {",
                         "        \"HelloWorld\" : {",
                         "            \"Type\" : \"Task\", ",
                         "            \"Resource\" : \"arn:aws:lambda:us-east-1:111122223333:function:HelloFunction\",",
                         "            \"End\" : true",
                         "        }",
                         "    }",
                         "}"
                      ]
                   ]
                },
          "RoleArn" : "arn:aws:iam::111122223333:role/service-role/StatesExecutionRole-us-east-1"
            }
}
