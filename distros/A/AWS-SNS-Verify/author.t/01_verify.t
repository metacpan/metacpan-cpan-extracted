use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib '../lib';

use_ok('AWS::SNS::Verify');


note "Happy path";

# this certificate is out of date, you need a new message and certificate as you're running these, which is why it is an author test

my $cert_string = <<END;
-----BEGIN CERTIFICATE-----
MIIFFzCCA/+gAwIBAgIQfXvtWTP5lfZLpmyNHLk1TDANBgkqhkiG9w0BAQUFADCB
tTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDlZlcmlTaWduLCBJbmMuMR8wHQYDVQQL
ExZWZXJpU2lnbiBUcnVzdCBOZXR3b3JrMTswOQYDVQQLEzJUZXJtcyBvZiB1c2Ug
YXQgaHR0cHM6Ly93d3cudmVyaXNpZ24uY29tL3JwYSAoYykxMDEvMC0GA1UEAxMm
VmVyaVNpZ24gQ2xhc3MgMyBTZWN1cmUgU2VydmVyIENBIC0gRzMwHhcNMTQwODIz
MDAwMDAwWhcNMTUwODIyMjM1OTU5WjBrMQswCQYDVQQGEwJVUzETMBEGA1UECBMK
V2FzaGluZ3RvbjEQMA4GA1UEBxQHU2VhdHRsZTEZMBcGA1UEChQQQW1hem9uLmNv
bSwgSW5jLjEaMBgGA1UEAxQRc25zLmFtYXpvbmF3cy5jb20wggEiMA0GCSqGSIb3
DQEBAQUAA4IBDwAwggEKAoIBAQDP/HD18qyBx4IgBvgVCkLTW18bULmoaaOQYtRY
yVpPxIFkNSHxT4uYH9knKUqddKQd1TEXHh0bF50lBiHZpuascNc3+FP2YKbF2t/z
a+zHfLipW01np85VDdIWedvB9TpnMdY9PQYTVx41+2fnei9WgjwXVM085WRSECh3
aRdkvOjwTN/Tlrgy3hoebVN3V5kB67b139m3xAlZjoB8MPdk/tlsk+wgVxuAY/gz
xGIZRJxlgEtsu2g8+rDkjS2tk3457Cz8aXRZSCGi+BB6yN2WhvWwPzSDJMDKxwXY
I8fGw0xutF4WHN414KBUp/s/+E6Ib7GxLUCwFon1swKRz9NxAgMBAAGjggFqMIIB
ZjAcBgNVHREEFTATghFzbnMuYW1hem9uYXdzLmNvbTAJBgNVHRMEAjAAMA4GA1Ud
DwEB/wQEAwIFoDAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwZQYDVR0g
BF4wXDBaBgpghkgBhvhFAQc2MEwwIwYIKwYBBQUHAgEWF2h0dHBzOi8vZC5zeW1j
Yi5jb20vY3BzMCUGCCsGAQUFBwICMBkaF2h0dHBzOi8vZC5zeW1jYi5jb20vcnBh
MB8GA1UdIwQYMBaAFA1EXBZTRMGCfh0gqyX0AWPYvnmlMCsGA1UdHwQkMCIwIKAe
oByGGmh0dHA6Ly9zZC5zeW1jYi5jb20vc2QuY3JsMFcGCCsGAQUFBwEBBEswSTAf
BggrBgEFBQcwAYYTaHR0cDovL3NkLnN5bWNkLmNvbTAmBggrBgEFBQcwAoYaaHR0
cDovL3NkLnN5bWNiLmNvbS9zZC5jcnQwDQYJKoZIhvcNAQEFBQADggEBABm5RaeH
sLtJftDeGghHAUkco8wkCshKQO1obhuMDJkJHAHbUrweP4Gw7WRhHNHo1jgA6Q61
NXik2w6H7SDVngCVIqOLFsr1DQ7fB5oSevMwjLvlaLxWBAvgKPSsjCt+QF1aNQiv
sfhOIgiJZTObBERsSs9FXWQ/vMkoisPKYJGn3KigzZj0GXSAB0do8Ejq8siBczgM
9o8NixqVvD7AOoE/QWXCtRDMRnQ5oIAc/Q9iUCJ8oAlbljDFkSqwgunpaG0iuHQZ
6Q4iHgmrgHM302H9fFxupyW46zwLH9gmbrUulmLRZT14bIzd0cZXqIl6nd8il4nq
kqQRCW8P2LDot4s=
-----END CERTIFICATE-----
END

my $body = <<END;
{
    "Type" : "Notification",
    "MessageId" : "a890c547-5d98-55e2-971d-8826fff56413",
    "TopicArn" : "arn:aws:sns:us-east-1:041977924901:foo",
    "Subject" : "test subject",
    "Message" : "test message",
    "Timestamp" : "2015-02-20T20:59:25.401Z",
    "SignatureVersion" : "1",
    "Signature" : "kzi3JBQz64uFAXG9ZuAwPI2gYW5tT7OF83oeHb8v0/XRPsy0keq2NHTCpQVRxCgPOJ/QUB2Yl/L29/W4hiHMo9+Ns0hrqyasgUfjq+XkVR1WDuYLtNaEA1vLnA0H9usSh3eVVlLhpYzoT4GUoGgstRVvFceW2QVF9EYUQyromlcbOVtVpKCEINAvGEEKJNGTXQQUkPUka3YMhHitgQg1WlFBmf+oweSYUEj8+RoguWsn6vluxD0VtIOGOml5jlUecfhDqnetF5pUVYMqCHPfHn6RBguiW+XD6XWsdKKxkjqo90a65Nlb72gPSRw6+sIEIgf4J39WFZK+FCpeSm0qAg==",
    "SigningCertURL" : "https://sns.us-east-1.amazonaws.com/SimpleNotificationService-d6d679a1d18e95c2f9ffcf11f4f9e198.pem",
    "UnsubscribeURL" : "https://sns.us-east-1.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:us-east-1:041977924901:foo:20b2d060-2a32-4506-9cb0-24b8b9e605e1",
    "MessageAttributes" : {
        "AWS.SNS.MOBILE.MPNS.Type" : {"Type":"String","Value":"token"},
        "AWS.SNS.MOBILE.WNS.Type" : {"Type":"String","Value":"wns/badge"},
        "AWS.SNS.MOBILE.MPNS.NotificationClass" : {"Type":"String","Value":"realtime"}
    }
}
END

my $sns = AWS::SNS::Verify->new(body => $body, certificate_string => $cert_string);

isa_ok($sns, 'AWS::SNS::Verify');

#is($sns->certificate_string, $sns->fetch_certificate, 'loading the certificate ok');

ok $sns->verify, 'does message check out';



note "Tampered body doesn't validate";

my $tampered_body = <<END;
{
    "Type" : "Notification",
    "MessageId" : "a890c547-5d98-55e2-971d-8826fff56413",
    "TopicArn" : "arn:aws:sns:us-east-1:041977924901:foo",
    "Subject" : "test subject",
    "Message" : "TAMPERED MESSAGE",
    "Timestamp" : "2015-02-20T20:59:25.401Z",
    "SignatureVersion" : "1",
    "Signature" : "kzi3JBQz64uFAXG9ZuAwPI2gYW5tT7OF83oeHb8v0/XRPsy0keq2NHTCpQVRxCgPOJ/QUB2Yl/L29/W4hiHMo9+Ns0hrqyasgUfjq+XkVR1WDuYLtNaEA1vLnA0H9usSh3eVVlLhpYzoT4GUoGgstRVvFceW2QVF9EYUQyromlcbOVtVpKCEINAvGEEKJNGTXQQUkPUka3YMhHitgQg1WlFBmf+oweSYUEj8+RoguWsn6vluxD0VtIOGOml5jlUecfhDqnetF5pUVYMqCHPfHn6RBguiW+XD6XWsdKKxkjqo90a65Nlb72gPSRw6+sIEIgf4J39WFZK+FCpeSm0qAg==",
    "SigningCertURL" : "https://sns.us-east-1.amazonaws.com/SimpleNotificationService-d6d679a1d18e95c2f9ffcf11f4f9e198.pem",
    "UnsubscribeURL" : "https://sns.us-east-1.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:us-east-1:041977924901:foo:20b2d060-2a32-4506-9cb0-24b8b9e605e1",
    "MessageAttributes" : {
        "AWS.SNS.MOBILE.MPNS.Type" : {"Type":"String","Value":"token"},
        "AWS.SNS.MOBILE.WNS.Type" : {"Type":"String","Value":"wns/badge"},
        "AWS.SNS.MOBILE.MPNS.NotificationClass" : {"Type":"String","Value":"realtime"}
    }
}
END

my $tampered_body_sns = AWS::SNS::Verify->new(body => $tampered_body, certificate_string => $cert_string);
throws_ok(
    sub { $tampered_body_sns->verify },
    qr/Could not verify the SES message/,
    "Tampered with body doesn't valiate",
);



note "Invalid cert doesn't validate";

my $invalid_cert_sns = AWS::SNS::Verify->new(body => $body, certificate_string => "Nopes");
throws_ok(
    sub { $invalid_cert_sns->verify },
    qr/X509/,
    "Invalid cert doesn't valiate",
);



done_testing();
