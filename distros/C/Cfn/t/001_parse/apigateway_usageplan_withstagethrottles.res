{
  "Type" : "AWS::ApiGateway::UsagePlan",
  "Properties" : {
    "ApiStages" : [ 
      {"ApiId" : { "Ref" : "MyRestApi" }, 
       "Stage" : { "Ref" : "Prod" },
       "Throttle": {
         "/": { "BurstLimit" : 20, "RateLimit" : 100 },
         "/myurl": { "BurstLimit" : 20, "RateLimit" : 100 }
       }
      } ],
    "Description" : "Customer ABC's usage plan",
    "Quota" : {
      "Limit" : 5000,
      "Period" : "MONTH"
    },
    "Throttle" : {
      "BurstLimit" : 200,
      "RateLimit" : 100
    },
    "UsagePlanName" : "Plan_ABC"
  }
}
