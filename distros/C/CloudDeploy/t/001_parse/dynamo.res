      {
         "Type" : "AWS::DynamoDB::Table",
         "Properties" : {
            "KeySchema" : {
               "HashKeyElement": {
                  "AttributeName" : "AttributeName1",
                  "AttributeType" : "S"
               },
               "RangeKeyElement" : {
                  "AttributeName" : "AttributeName2",
                  "AttributeType" : "N"
               }
            },
            "ProvisionedThroughput" : {
               "ReadCapacityUnits" : "5",
               "WriteCapacityUnits" : "10"
            }
         }
      }
