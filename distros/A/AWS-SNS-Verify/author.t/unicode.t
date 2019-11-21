use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib '../lib';
use_ok('AWS::SNS::Verify');

# this certificate is out of date, you need a new message and certificate as you're running these, which is why it is an author test

my $cert_string = <<END;
-----BEGIN CERTIFICATE-----
MIIFazCCBFOgAwIBAgIQDnuRfDcLJCFd0+nXpG2L3DANBgkqhkiG9w0BAQsFADBG
MQswCQYDVQQGEwJVUzEPMA0GA1UEChMGQW1hem9uMRUwEwYDVQQLEwxTZXJ2ZXIg
Q0EgMUIxDzANBgNVBAMTBkFtYXpvbjAeFw0xOTAyMDUwMDAwMDBaFw0yMDAxMjMx
MjAwMDBaMBwxGjAYBgNVBAMTEXNucy5hbWF6b25hd3MuY29tMIIBIjANBgkqhkiG
9w0BAQEFAAOCAQ8AMIIBCgKCAQEArvAsTqmW94EiC9gelZrEdR3Y2jJJwLOaRnxK
oY/J/CBUEGGzfqaUBXwWnjVOImzirE57j/5ItnpW9k5kByIs7aPDuiaqaCn6Oous
FqQXyem8DJp5WoFZSPhKDtLVRaOzlbMgsDIYVpcqOWfubpj7oD7/nWwICtPX7eVa
jUkbaCcQExS1GY83qoL4GUpeUPN+PQ9ExNupjvi/p6lLBx2vPpcYDs2QFkT12ol6
hxUCI9LRbNM/InWVP7qr9iBS3eMIP9jpr4oV7D2keztIaonLVe93psXzSh3YJm/d
lnbFlIxseBrAMrUgrJE0MXcpgiCv8HrdAYfIB6XBaGA5TdXIcwIDAQABo4ICfTCC
AnkwHwYDVR0jBBgwFoAUWaRmBlKge5WSPKOUByeWdFv5PdAwHQYDVR0OBBYEFH+5
YRwjoZnCPO5z41lYfsedlqomMBwGA1UdEQQVMBOCEXNucy5hbWF6b25hd3MuY29t
MA4GA1UdDwEB/wQEAwIFoDAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIw
OwYDVR0fBDQwMjAwoC6gLIYqaHR0cDovL2NybC5zY2ExYi5hbWF6b250cnVzdC5j
b20vc2NhMWIuY3JsMCAGA1UdIAQZMBcwCwYJYIZIAYb9bAECMAgGBmeBDAECATB1
BggrBgEFBQcBAQRpMGcwLQYIKwYBBQUHMAGGIWh0dHA6Ly9vY3NwLnNjYTFiLmFt
YXpvbnRydXN0LmNvbTA2BggrBgEFBQcwAoYqaHR0cDovL2NydC5zY2ExYi5hbWF6
b250cnVzdC5jb20vc2NhMWIuY3J0MAwGA1UdEwEB/wQCMAAwggEEBgorBgEEAdZ5
AgQCBIH1BIHyAPAAdgDuS723dc5guuFCaR+r4Z5mow9+X7By2IMAxHuJeqj9ywAA
AWi7Mu+5AAAEAwBHMEUCICjzfKhUDa04qWsE9ylpT3uVQR1lkQoOK3BL/jmBqm68
AiEA2x/7MUblEQNBKWtWhLmFtRv2a2KPBpUvN1JCFvlx5FIAdgCHdb/nWXz4jEOZ
X73zbv9WjUdWNv9KtWDBtOr/XqCDDwAAAWi7MvCPAAAEAwBHMEUCIDc9rV+Lz9Mx
8rpwT38zwxyxlU81FFe6/S23FDx/UqedAiEApAItYGLRBnC0YlXe5OCF5fsL9HWy
gV0fhTs6r3K09twwDQYJKoZIhvcNAQELBQADggEBAAz9vw2lMiEDgxN/jCju2gH+
mkDSPyvKMBc9vPnLySBqpiu73cnvDlXWe1OXnyHXjAXWlrHlHQs5sIX6cfipUDbC
siY7b2mt/uqASWMa1Qm6ROzd9J4peXYQGJEOaOBuIbDyzphlGCJc/fMwdVjU6FfH
A2NL3DZnNw5r26FydzfN0HWu9B9UuvNrQ7v9XqvoBOA1QkWZpB3Hcnmu2KGNFugL
5MFqgeb5yYxXORIDFATQVJRvxf43L/StvA8D3OjNiCqw057tuviFwo0WABYv1K2e
9fuuyR7idsWT2+veCDK6gLdWN5hEalYIYPbgeWuhAh6CZqfPdURGbDhf2ygruhE=
-----END CERTIFICATE-----
END

my $unicode = <<END;
{ 
"Type" : "Notification", 
"MessageId" : "95841c0a-329b-5910-bcc0-4a45a34aa6c7", 
"TopicArn" : "arn:aws:sns:us-east-1:041977924901:test", 
"Message" : "A Test Banana:\uD83C\uDF4C", 
"Timestamp" : "2019-11-20T19:10:09.894Z", 
"SignatureVersion" : "1", 
"Signature" : "DRcI8zgRFKXD/N679D3v9q8uYEt0HYJYUNQoGsNZ3JF6x5mmoEG2e9u+5MwwS2tkOsvwQQZg3vfM8bpiNMcvzqIruZPA4b+MRjyHOPqHEPMmIeM8VsZaqJJVSXErQp/q9xJka6JNOzIKA34TjR5WaDJjuHBgNVaftimlPvpeqKTWSQ9UPdw0wh9Fj1fDlGqr8eVs9LhhAx7EKSNgG1lNuJykf5x4fMq/3SQv30wmtQZkVVYBIUMZ1lqjgWK6mH/GatdqFSQHs0LN1yl2SYqPYr0NeykXlNyLtwmobg4dwmcNIhlmghJo8/6krC8HBFovKaqgpsa95D1tpbQ9dW38Dg==",
"SigningCertURL" : "https://sns.us-east-1.amazonaws.com/SimpleNotificationService-6aad65c2f9911b05cd53efda11f913f9.pem", 
"UnsubscribeURL" : "https://sns.us-east-1.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:us-east-1:041977924901:test:5b4ab24c-a248-4b55-84ef-7143a86f483f" 
} 
END
my $sns = AWS::SNS::Verify->new(body => $unicode, certificate_string => $cert_string);
ok $sns->verify, 'does unicode message check out';





done_testing();
