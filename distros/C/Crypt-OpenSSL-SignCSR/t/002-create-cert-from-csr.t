use strict;
use warnings;

use Test::More;
use File::Which qw/which/;
use File::Temp qw/tempfile/;
use File::Slurper qw/write_text/;

use Crypt::OpenSSL::SignCSR;

my $privkey = << 'PRIVKEY';
-----BEGIN PRIVATE KEY-----
MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCSar7AWulU+FEj
sUivJd3+Wme7iFDA5X/HeR6h7CKU4kIHXJf5TdkR0Mo/zRE8TReHxJH8dm2dKOCE
m8b+iHs3xQo7lnGuzC+TmdW2Q8Emx7A/Mv80vuKjh7Kcld5Ur6JnUTiSaB4AVktU
U88LktBRkPd5e+wgT1m67uuihhrKpLnvSaJozKjONnnhisW3AW1eAOKmvarFfpvy
zz2utyQtecoh0HdFfS+yrP7yWLo26KwWCHY4OO7SdSp/ZdcrQBvWBK6ceuvPJGP8
ymxRWaZK2AHeTF0FuqJ8Fryna2Y991G+3/oczaym4iWscaI5V74lRF3mK/m4PI3S
kgPTgEPjAgMBAAECggEAJIv1giEPJfD3m9+oI2Ph1hft1Z8QfR2r9/fxH/zHov8Y
+SpxGr8GRE6n9SX0O+eITJDR2cEb2kM2S5Nwp98cVo7d34LNbJK1+3NGJ4EhCNOG
WDgcAKf2/VelSzWTcfMHKB/bbZwEhRQFKI7k2uAyFHIJe67lgSkdXi497erobBUy
V0ily+8nYZKc/vo6oClx0cQ1BjCU6RMkE8yt1k+7TgqzwCkit+kVVgqSHJXr482O
m8cVEwJX8ReUgtg38W4Ly2oWRiOiF4G19ViJxNaVRPRTNCCOlBRnlxEMZCXW4CLo
LZBRPfiFxZZtaNAoDqefyUdRM8W2rLsayaSH+v7S7QKBgQDBlIvrWg1m/BnSdSGl
DP+Ccj2InD2A81TqYXF6Y5aB3yEuKzDRwgWstNd2H5OIm1+a8gk6jV1Xm7sknBSD
bxFDXHWRySJWNI18Oh+0WSEOJ3u8j5KrMyF6nFrCYKiY8veLnBszlYgcbKKfmKYv
dhYd6wSFVi3r2rjomLmo13qA1QKBgQDBoQPCpQlWE0aj4KKJIBCs4DKjOBHlfE9H
74RAFOK/LsH+yIu+ERC5DN/mV2foiYYaUFAgfanpndEColKDDnGqM0eVko0jnp1M
co7QZHJOs/OA7qxhsiBJCQ/j4Q1a54UB9rk+tgEf/RZbr/FmZxYtJsmtjn/LxWbr
tPAf9mZN1wKBgGrg8T/IQI4Tss4YDbNrMcd7+61pVivULZYapuTEB109LLyo7BNj
5G4uiqeVV4edAXQzHhVN57NvMCxOYKUQtZ9TdTZArsyZx2RHUynn6/A8rHy3aGtN
l7ZyjUm0xGFuBG74iaw5ayUGdeNYDKk3sY5jK+PSaRhHcsA5Uoh+MAzhAoGAeiCM
tqBRmzDdRU/SNJs86U0fo0MiRpR5jO3NhH2n5t4fDgx/14n7+jvcnPRUXZ8gLkip
wVSBbxBTXE31rSPXHXrqk7SzwNuyax12Zop0bp+h3pirsZMgOfC1TQ4N1mBgzDRJ
8vvpCbwf9gSrReOPYTstyYIvqN8BY3nkWsSXElECgYA8MHCbPiE5v1SyE6B8yKO5
1/9Yg1unrwPBj6Q7YOUZLGaaWVuJfIvjkM/dOOypi170tMYWiOKk6RNz+j841thh
N3nGJfwRq+92jboNoqrhMxmMXFkPRIfpTBCIno6+i3ashVPND1fRrp/DWzA9hWGN
1ib27M8VSoEbTa+n4bmf3Q==
-----END PRIVATE KEY-----
PRIVKEY

my $signer = Crypt::OpenSSL::SignCSR->new(
                                    $privkey,
                                    {
                                        days    => 365,
                                        format  => "pem",
                                        digest  => "SHA512",
                                    }
                                    );

isa_ok($signer, "Crypt::OpenSSL::SignCSR");

my $request = <<'CERTREQUEST';
-----BEGIN CERTIFICATE REQUEST-----
MIIDADCCAegCAQAwLzELMAkGA1UEBhMCQ0ExETAPBgNVBAoMCFhNTDo6U2lnMQ0w
CwYDVQQLDARwZXJsMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAkmq+
wFrpVPhRI7FIryXd/lpnu4hQwOV/x3keoewilOJCB1yX+U3ZEdDKP80RPE0Xh8SR
/HZtnSjghJvG/oh7N8UKO5Zxrswvk5nVtkPBJsewPzL/NL7io4eynJXeVK+iZ1E4
kmgeAFZLVFPPC5LQUZD3eXvsIE9Zuu7rooYayqS570miaMyozjZ54YrFtwFtXgDi
pr2qxX6b8s89rrckLXnKIdB3RX0vsqz+8li6NuisFgh2ODju0nUqf2XXK0Ab1gSu
nHrrzyRj/MpsUVmmStgB3kxdBbqifBa8p2tmPfdRvt/6HM2spuIlrHGiOVe+JURd
5iv5uDyN0pID04BD4wIDAQABoIGLMIGIBgkqhkiG9w0BCQ4xezB5MA4GA1UdDwEB
/wQEAwIFoDAuBgNVHSUEJzAlBggrBgEFBQcDAQYJYIZIAYb4QgQBBgorBgEEAYI3
CgMDBgIrBDAcBgNVHREEFTATgRF0aW1sZWdnZUBjcGFuLm9yZzAZBgMqAwMEEhYQ
TXkgbmV3IGV4dGVuc2lvbjANBgkqhkiG9w0BAQsFAAOCAQEARelowjoheanqW+yr
P9wykx6jFYoEMnNvWUhB7YdepLcsJ4FvWLxEJkRtS67+Pd/fDm0vH85L/osIRntw
GEyGQK+AnsDiSTHGjMJlN/UIMTPEC8a/Gy219UKiOAsMDZ3tLvOqktRDZz75zsDP
KL+zPbyErf1igZGuch8rHFEeNKZCI3RMbv+je2F53ZuqJBf5XC9ek1ZACb9mgoT3
KUjuxXooXEsUCEYLI/EYmjWkCrZFPEszRM6/unxM1hqjO4Zex3x35UQANgH68s/8
tTMXV4adoIn/tQetbhkgPMQ6kqPwTVfeZ4idjhz2Ex/zotfKjoJqupEOjSOBkeC2
bczN2A==
-----END CERTIFICATE REQUEST-----
CERTREQUEST

my $cert = $signer->sign($request);

my $certfile = tempfile();
my ($certfh, $certfilename) = tempfile();
write_text($certfilename, $cert);

my $openssl = which('openssl');

my $result;
eval {
    $result = `$openssl x509 -in $certfilename -text`;
};

like($result, qr/Issuer:.*XML::Sig.*perl/, "Certificate - Issuer OK");
like($result, qr/Signature Algorithm: sha512WithRSAEncryption/, "Certificate - Signature OK");

ok($signer->get_days() eq 365, "Days were set successfully");
ok($signer->set_days(36500), "Days set successfully");
ok($signer->get_days() eq 36500, "Days were set successfully");

like($signer->get_digest, qr/SHA512/, "Digest was correctly set"); 
ok($signer->set_digest("SHA384"), "Digest set Succesfully");
like($signer->get_digest, qr/SHA384/, "Digest was correctly set"); 

like($signer->get_format(), qr/pem/, "Format was correctly set"); 
ok($signer->set_format("text"), "Format set Succesfully");
like($signer->get_format(), qr/text/, "Format was correctly set"); 

done_testing
