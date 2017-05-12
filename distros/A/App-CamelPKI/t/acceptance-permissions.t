#!perl -w

use strict;

=head1 NAME

acceptance-permissions.t - Try to access Camel-PKI using the wrong
credentials, and fail (hopefully)

=cut

use Test::More;
use Test::Group;
use App::CamelPKI;
use App::CamelPKI::Test qw(jsonreq_remote);
use File::Slurp;

my $webserver = App::CamelPKI->model("WebServer")->apache;
if ($webserver->is_installed_and_has_perl_support && $webserver->is_operational) {
	plan tests => 2;
} else {
	plan skip_all => "Apache is not insalled or Key Ceremnoy has not been done !";
}
$webserver->start(); END { $webserver->stop(); }
$webserver->tail_error_logfile();

my $port = $webserver->https_port();

=pod

We try to perform the same access as C<acceptance-issue-certifcates.t>
in the same directory, with the same request structure (although it
doesn't matter all that much since the request will fail anyway)

=cut

my $url = "https://localhost:$port/ca/template/vpn/certifyJSON";
my $req = {
     requests => [
      { template => "VPN1",
        dns      => "bar.example.com",
      },
      { template => "VPN1",
        dns      => "bar.example.com",
      },
      { template => "VPN1",
        dns      => "bar.example.com",
      },
      { template => "VPN1",
        dns      => "bar.example.com",
      }
     ],
   };

test "try to operate CA without a certificate" => sub {
    my $response = jsonreq_remote($url, $req);
    is($response->code, 403, "permission denied");
    unlike($response->code, qr|<html|, "error message is in plain text");
};

test "try to operate CA with a wrong certificate" => sub {
    my $keypem = "-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEAs5y3jQ8tg2z/E7E+URZLyvS3tASALqGVt8rPd4U8J5/Wv+ee
ZAbnUcGZChzk70bywc/jn34vxbqHX5THDEgVodGI8hKgQgVHfnydsE0Q0GmAkyKV
DiM6Ve9I8F+TnoZmZGkIQD737BnmDMXOBdleE5c/XBkIDch2k75A9j32zhfh3yQy
Q9oVGPKVR5chmCSNLoni6O9VXxcBKxQAYxfxgA9mx6XHLi1iaYy9Q8Xrl7jMR4H7
7+7+eXJwXLqPxLVPahXhN10dsTmIajmKhL5uHwxeRjlNeZm4nFfhTQo46d7ZGGsX
pW6xHFeXqNJhLBHCMn1AkJqN03NnXwJmpjbuCwIDAQABAoIBABKuzYT1vDU8hDfn
KuVCXXXqCKXIBhFTq4Anr3buO/ifLrZdgGNFOJCPg7zCjqm5Bo1Uc4fml0+I/IXb
suy7HszrP8R2XYcgh3RHwBtTmNkk8EPdyAVlcq73qe2e83r83e+54SrVofJEK2LO
vIRtPNTq2aNZ0zWj0XnCw30Zqu967d4gRocG7WuVlDi2jugZjA6Tv3+WVPL6GeTl
keUSJNrN1q7dsyzMwJZpWTCForu7/S03hSpuIL4waiTY1G82H4wHIG//AYv/Udz7
7vYJio2ZEAG8wG7wECpxRolhEkYjdcr2riHtKEu4KRufavzz2exkgajjIqNCb+hy
80hQqgECgYEA2H+ru6ADc1dutVX5LR7aS5AHkwfL3gtd3a1YXUxOTX4QvQNjfJOd
yPWLGegreAJaiUYelKQ7jm7Il/WVaaD3MtB72FxR4BVRzucLl5tOK7Rf7+u5Mvpx
JYyYtZ29GAEzEnEiQEP2lxVCCQxnjh1DHm+UCXkZ83SzxVHBTcsacQECgYEA1GIh
p0wsFgn0iqZLKhzRLdLwymcieDd7N+Hx6MN+RjOwa+16W1VtowXnI/t5SE7tyxck
magIfTX+cKvUsxM8X+O+cZY61nNHE9D/T1TSXRydbLVs+4bp0bgBhyPEtfyyY080
XwmfEtJ0f3w25ywkanIxbZER1sdBmSfsH9SxEwsCgYBpbgsIjM0BX2OnZR26Llsq
DxLRNCvAjxKAAImWrbE4JZsrILpTEWP2WDUMQbbhc2v5i68avbvPCf4fmlXPobag
BU06OQMaN+el9Xf8tYHk4KsToFyJCdMN8SDw2MccKIFhiryeRTqRqqWE2IiZeYCV
EssprdLIb12YSs7y/mR7AQKBgAb+TDlkCreXEFRYcXUrib/GiGNBziLDQO1wJTUS
6t+I6DBFm5fSUk/h6+CFcVLuNmpPksb0f4MP+hbfsZtL8Nr/ds/qsHlLRnXileWY
12x1esGPn80QfjaHppU6mkmbzovymbjfajuGboucHXqzO2e95t7CviGiYgiXBfFu
YX5NAoGAHCrBPFrqh4XUxlfUqru3Lyv5AxvcnxOVLkjdupGSjl7NQpw6rWZJAWgJ
0rS5C3UGLd5cAunYsK/hrT5N+fbM2HTIiWDObm/QaCB6Zw6SOMYyjyYwP2ocCJ9B
/oR7UgGwVpwVze/9TWM6dB8Amh0jss292gzRZdRvWcgCp7DwxrA=
-----END RSA PRIVATE KEY-----
";

    my $certpem = "-----BEGIN CERTIFICATE-----
MIID8DCCAtigAwIBAgIBBzANBgkqhkiG9w0BAQsFADCBuTEeMBwGA1UEChMVRWNs
YWlyIERpZ2l0YWwgQ2luZW1hMR4wHAYDVQQLExVFY2xhaXIgRGlnaXRhbCBDaW5l
bWExMTAvBgNVBAMTKC5BQyBvcGVyYXRpb25uZWxsZSBFY2xhaXIgRGlnaXRhbCBD
aW5lbWExRDBCBgNVBC4TO0RCOjJFOkY3Ojk5OkU3OjkzOkMzOkVEOjVBOjY1OkIw
OjBDOkZEOjY2OjIwOkU5OjA1OjM2OkNCOkM5MB4XDTA3MDQwMjIwNTUxMFoXDTM3
MDQwMjE1NTkwN1owazEfMB0GA1UECgwWRWNsYWlyRGlnaXRhbENpbmVtYS5mcjEQ
MA4GA1UECwwHRURDLVBLSTEdMBsGA1UECwwUcsODwrRsZXMgc3DDg8KpY2lhdXgx
FzAVBgNVBAMMDmFkbWluaXN0cmF0ZXVyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
MIIBCgKCAQEAs5y3jQ8tg2z/E7E+URZLyvS3tASALqGVt8rPd4U8J5/Wv+eeZAbn
UcGZChzk70bywc/jn34vxbqHX5THDEgVodGI8hKgQgVHfnydsE0Q0GmAkyKVDiM6
Ve9I8F+TnoZmZGkIQD737BnmDMXOBdleE5c/XBkIDch2k75A9j32zhfh3yQyQ9oV
GPKVR5chmCSNLoni6O9VXxcBKxQAYxfxgA9mx6XHLi1iaYy9Q8Xrl7jMR4H77+7+
eXJwXLqPxLVPahXhN10dsTmIajmKhL5uHwxeRjlNeZm4nFfhTQo46d7ZGGsXpW6x
HFeXqNJhLBHCMn1AkJqN03NnXwJmpjbuCwIDAQABo1AwTjAfBgNVHSMEGDAWgBTb
LveZ55PD7VplsAz9ZiDpBTbLyTAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBR0SQJp
1JPwvty0JTNEROySQqnXjTANBgkqhkiG9w0BAQsFAAOCAQEA4BPpqR+YIul4hgkf
bdoQdptrazzV7qRmN3mMOGxHJkDvUSpd5LSkD+nKBUETbPGJVmUo5rx2WiXofuhn
t6RvqQPLyO9XN/8rCAV32/gS/kDxN0urItLNEo5V1rrvjXx7LsmIBp8JGV7eauzF
Br8w8t2OiQwEUgjjGLMTmLtI88zYP6vI2UopUhNHf9PVb2b1FoTXsznvKl2u1CdL
1Tk2ehb/eX1hH03CiN+YweNbOH8L+A+ULCWmqLtQK50WKtnhqZPE9HBKgx3Lwfsj
ZsgQNgF5GP5gG4POS+at4CxLApoQs2wZ3B9t89wAlzHMqweuMvTQlEKrz84V8fzH
hr/86g==
-----END CERTIFICATE-----
";

    my $response = jsonreq_remote
        ($url, $req, -key => $keypem, -certificate => $certpem);
    is($response->code, 500,
       "Server should close the connection on our face");
};
