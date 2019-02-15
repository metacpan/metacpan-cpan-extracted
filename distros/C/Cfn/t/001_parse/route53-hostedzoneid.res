{
            "Type" : "AWS::Route53::RecordSet",
            "Properties" : {
                "HostedZoneId" : "/hostedzone/Z3DG6IL3SJCGPX",
                "Comment" : "CNAME for my frontends.",
                "Name" : "mysite.example.com.",
                "Type" : "CNAME",
                "TTL" : "900",
                "ResourceRecords" : [
                    {"Fn::GetAtt":["myLB","DNSName"]}
                ]
            }
        }
