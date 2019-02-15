{
         "Type": "AWS::IoT::Thing",
         "Properties": {
            "ThingName": {
               "Ref": "NameParameter"
            },
            "AttributePayload": {
               "Attributes": {
                  "myAttributeA": {
                     "Ref": "MyAttributeValueA"
                  },
                  "myAttributeB": {
                     "Ref": "MyAttributeValueB"
                  },
                  "myAttributeC": {
                     "Ref": "MyAttributeValueC"
                  }
               }
            }
         }
      }

