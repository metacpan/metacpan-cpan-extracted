{
  "Type": "AWS::RDS::OptionGroup",
  "Properties": {
    "EngineName": "mysql",
    "MajorEngineVersion": "5.6",
    "OptionGroupDescription": "A test option group",
    "OptionConfigurations": [
      {
        "OptionName": "OEM",
        "DBSecurityGroupMemberships": [
           "default"
        ],
        "Port": "3306"
      }
    ]
  }
}

