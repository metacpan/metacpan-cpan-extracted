use strict;
use warnings;

use Test::More;
use File::Which qw/which/;
use File::Temp qw/tempfile/;
use File::Slurper qw/write_text/;

use Crypt::OpenSSL::RSA;
use Crypt::OpenSSL::PKCS10 qw( :const );
#use Crypt::OpenSSL::Random;

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

my $priv = Crypt::OpenSSL::RSA->new_private_key($privkey);


my $req = Crypt::OpenSSL::PKCS10->new_from_rsa($priv);
isa_ok($req, "Crypt::OpenSSL::PKCS10");

$req->set_subject("/C=CA/ST=New Brunswick/O=XML::Sig/OU=perl");
$req->add_ext(Crypt::OpenSSL::PKCS10::NID_key_usage,"critical,digitalSignature,keyEncipherment");
$req->add_ext(Crypt::OpenSSL::PKCS10::NID_ext_key_usage,"serverAuth, nsSGC, msSGC, 1.3.4");
$req->add_ext(Crypt::OpenSSL::PKCS10::NID_subject_alt_name,"email:timlegge\@cpan.org");
#$req->add_custom_ext('1.2.3.3',"My new extension");
$req->add_ext_final();

$req->sign();

my $request = $req->get_pem_req();

like ($request, qr/CERTIFICATE REQUEST/, "Sucessfully created a Certificate Request");
my $signer = Crypt::OpenSSL::SignCSR->new(
                                            $privkey,
                                            {
                                                format  => "pem",
                                                days    => 760,
                                                digest  => "SHA512",
                                            }
                                        );

isa_ok($signer, "Crypt::OpenSSL::SignCSR");

my $cert = $signer->sign($request);

my $certfile = tempfile();
my ($certfh, $certfilename) = tempfile();

write_text($certfilename, $cert);

my $openssl = which('openssl');

my $result;
eval {
    $result = `$openssl x509 -in $certfilename -text`;
};

unlink $certfilename;

like($result, qr/Issuer:.*XML::Sig.*perl/, "Certificate - Issuer OK");
like($result, qr/Signature Algorithm: sha512WithRSAEncryption/, "Certificate - Signature OK");

done_testing
