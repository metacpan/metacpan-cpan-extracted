{
    "Type" : "AWS::Route53::RecordSetGroup",
    "Properties" : {
        "HostedZoneId" : { "Ref" : "myHostedZoneID" },
        "RecordSets" : [{
            "Name" : { "Ref" : "myRecordSetDomainName" },
            "Type" : "A",
            "AliasTarget" : {
                "HostedZoneId" : "Z2FDTNDATAQYW2",
                "DNSName" : { "Ref" : "myCloudFrontDistributionDomainName" }
            }
        }]
    }
}
