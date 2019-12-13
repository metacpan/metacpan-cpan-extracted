{
      "Properties": {
        "AnalyzerName": "DevAccountAnalyzer",
        "ArchiveRules": [
          {
            "Filter": [
              {
                "Eq": [
                  "123456789012"
                ],
                "Property": "principal.AWS"
              }
            ],
            "RuleName": "ArchiveTrustedAccountAccess"
          },
          {
            "Filter": [
              {
                "Contains": [
                  "arn:aws:s3:::docs-bucket",
                  "arn:aws:s3:::clients-bucket"
                ],
                "Property": "resource"
              }
            ],
            "RuleName": "ArchivePublicS3BucketsAccess"
          }
        ],
        "Tags": [
          {
            "Key": "Kind",
            "Value": "Dev"
          }
        ],
        "Type": "ACCOUNT"
      },
      "Type": "AWS::AccessAnalyzer::Analyzer"
    }
