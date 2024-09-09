use strict;
use warnings;
use Test::More;
use Digest::SHA qw/sha256_hex/;
use Crypt::OpenSSL::Guess qw/openssl_version/;

my ($major, $minor, $patch) = openssl_version();
BEGIN { use_ok('Crypt::OpenSSL::PKCS12') };
my $openssl_output =<< 'OPENSSL_END';
MAC: sha1, Iteration 100000
MAC length: 20, salt length: 20
PKCS7 Data
Shrouded Keybag: PBES2, PBKDF2, AES-256-CBC, Iteration 10000, PRF hmacWithSHA256
Bag Attributes
    friendlyName: wile e coyote
    localKeyID: 54 69 6D 65 20 31 36 35 39 38 30 32 39 34 31 36 33 32 
Key Attributes: <No Attributes>
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCP18SdkO7OL1I3
heudIrke5tCctdgEJkODSMK60aiM6XGKzRBGNrvc50zp1vXxgM7MJsewQSLmlu9Q
EtEugoiZshAoFm5/UX/TzVa1cxndF6GqKXTgeSbWUuJsG4dyvc8cvWS+qZbqkBKr
H/TkzQ6X1HMrVh5ccKqpJTr8orovJO0H/mZn2f05hjVaUyHVoECqsSPYuP9qznTh
9/+LQUN/QG5uhoUze10A8DWQeq8zferTrUm3YkXsRWhBpJ74tXHiqOjwBjSR9nsX
RPZBIGeSHQZKamLjKTclShi6LItDHAoAyFD+NdUyjbwuZHPbg/fQJ8cimCVJuRA5
6TZyDhaVAgMBAAECggEAEc+i3evbVhaP9KYVhbCOAaCNBkqSA/mE9JWm3yEk4MXr
NEeuEzOl0XWmlXHzpELR2H+YzF9UZf8chOq/kiXBql5dF8mnRwadcGmFqhQliLXr
Y7mcaks2HuXGeaJzBCcypRlihyVStZq/ZQcg+M/XVb+Nvzj7q3CcATPF+RBhQ4L8
cf5qBZZIiuzTSzWhQtdkFcgFD0S7hnSZ/pCdo+ZZ7MMwlWsMPV9KU8i0NKSRWilr
wLHICUftnIZ+aHO3TALZ7UTuxgVT8yTnHGCyj+4bNhRaewyie75NWfbWeRowteti
TgFzvhArHLHaMQ/KVfz4svA+X9aJlWzV/ycFXVRQpQKBgQDILg+eYdcpJkCAQksc
wURI7CTDL2jYqE2Pl4JIPJ7gVV7Y/PFmjzanmN1FZSRWhRvkN2OpVfjbJGlHg5Qk
xvQQo7vzeuavcFsi7bIG0Ks92kDdIivWSKgPp6oCmV0R+D5gpGEeWZVzOpXQIpZj
AnoJ75AVFdy6ZlAVjNtKsKoZtwKBgQC39A7E3mkZH8DLhbiSJARtsPrj2rCgjhG2
J7U2dHV4fEbuix2Bju0dCNWEdWJVkQ1DVXr5RtG2mq6Tqwmz5svS32AqVLi+Ds9L
H/VUrw5xauZ1dJ1kjx97tiaWRaLHPYzdJeX9wT3zt8W8MViK4HFJFMW2Rj6C9aF3
ONYhX5tCEwKBgBORHQm4OpXVHVzsHfdzlL8kBfvmOHNlEB/HCX8SHd2Dur+vCdGi
kg8TzB0qY8DpRe6q010MAEU7a+cHn4VwxQ6TUp3cF4xyiRYC8fHkl7h2Cv0SiAJs
G7FcDCww3X4SK9a6epvC2e7nfRlZKCYJafBqsES/XFIECjPxDsZgOmBFAoGAXFFV
YCOmZv9yiDFR0bXVqx8YqmVEIy9pYBtJbEzB73efOXQDmNOb1+hpD5LBiOPE3jf2
AUgzUwsJ9f3uXqTDQc7suhHOrUNNcQxW2OsJuo3FnsipfJ//Uty1PNExwf/3w7yT
Ueg7KSbfS3UQVJITCHQuTS2vjZWsNOMHQ7RxfJUCgYEAjyu2b6Lzae8ZDUSHbeBP
faZHOjkkUK2W8Ee3xGNBAmArnJp+yx0BLa6ZD2xWX3NAeGtRJK/l/lgYsb7/kAvi
iS81NOQKkH8bC2SfqRkrlUjgGnYz2DVhQrbHw/BuiaIffqeY19WPSjyH1f9GPgog
NnkSzXchhFTmhMqqxQ1wlPc=
-----END PRIVATE KEY-----
PKCS7 Encrypted data: PBES2, PBKDF2, AES-256-CBC, Iteration 10000, PRF hmacWithSHA256
Certificate bag
Bag Attributes
    friendlyName: ssl.com ev root certification authority rsa r2
    2.16.840.1.113894.746875.1.1: <Unsupported tag 6>
subject=C = US, ST = Texas, L = Houston, O = SSL Corporation, CN = SSL.com EV Root Certification Authority RSA R2
issuer=C = US, ST = Texas, L = Houston, O = SSL Corporation, CN = SSL.com EV Root Certification Authority RSA R2
-----BEGIN CERTIFICATE-----
MIIF6zCCA9OgAwIBAgIIVrYpzTS8ePYwDQYJKoZIhvcNAQELBQAwgYIxCzAJBgNV
BAYTAlVTMQ4wDAYDVQQIDAVUZXhhczEQMA4GA1UEBwwHSG91c3RvbjEYMBYGA1UE
CgwPU1NMIENvcnBvcmF0aW9uMTcwNQYDVQQDDC5TU0wuY29tIEVWIFJvb3QgQ2Vy
dGlmaWNhdGlvbiBBdXRob3JpdHkgUlNBIFIyMB4XDTE3MDUzMTE4MTQzN1oXDTQy
MDUzMDE4MTQzN1owgYIxCzAJBgNVBAYTAlVTMQ4wDAYDVQQIDAVUZXhhczEQMA4G
A1UEBwwHSG91c3RvbjEYMBYGA1UECgwPU1NMIENvcnBvcmF0aW9uMTcwNQYDVQQD
DC5TU0wuY29tIEVWIFJvb3QgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkgUlNBIFIy
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAjzZlQOHWTcDXtOlG2mvq
M0fNTPl9fb69LT3w23jhhqXZuglXaO1XPqDQCEGD5yhBJB/jchXQARr7XnAjssuf
OePPxU7Gkm0mxnu7s9onnQqG6YE3Bf7wcXHswxzpY6IXFJ3vG2fThVUCAtZJycxa
4bH3bzKfydQ7iEGonL3Lq9ttewkfokxykNorCPzPPFTOZw+oz12WGQvE43LrrdF9
HSfvkusQv1vrO6/PgN3B0pYEW3p+pKk8OHakYo6gOV7qd89dAFmPZiw+B6KjBSYR
aZfqhbcPlgtLyEDhULouisv3D5oi53+aNxPN8k0TayHRwMwi8qFG9kRpnMphNQcA
b9ZhCBHqurj26bNg5U257J8UZslXWNvNh2n4ioYSA0e/ZhN2rHd9NCSFg83XqpyQ
Gp8hLH94t2S42Oim9HizVcuE0jLEeK6jj2HdzghTreyI/BXkmg3mnxp3zkyPuBQV
PWKchjgGAGYS5Fl2WlPAApiiECtoRHuOec4zSnaqW4EWG7WK2NAAe15itAnWhmMO
pgWVSbooi4iTsjQc2KRVbrcc0N6ZVTsj9CLg+SlmJuwgUHfbSguPvuUCYHBBXtSu
UDkiFCbLsjtzdFVHB3mBOagwE0TlBIqulhMlQg+5U8Sb/M3kHN48+qvWBkofZ6aY
MBzdLNvcGJVXZsb/XItW9XcCAwEAAaNjMGEwDwYDVR0TAQH/BAUwAwEB/zAfBgNV
HSMEGDAWgBT5YLvU49U09rj1BoAlp3PbRmmonjAdBgNVHQ4EFgQU+WC71OPVNPa4
9QaAJadz20ZpqJ4wDgYDVR0PAQH/BAQDAgGGMA0GCSqGSIb3DQEBCwUAA4ICAQBW
s47LCp1Jjr+kxJG7ZhcFUZh1++VQLHqe8RT6q9OKPv+RKY9ji9i0qVQBDb6Thi/5
Sm3HXvVX+cpVHBK+Rw82xd9qt9t1wkclf7nxY/hoLVUE0fKNsKTPvDxeH3jnpaAg
cLAExbf3cqfeIg29MyVGjGSSJuM+LmOW2puMPfgYCdcDzH2GguDKBAdRUNf/ktUM
79qGn5nX67evaOI5JpS6aLe/g9Pqemc9YmeuJeVy6OLk7K4S9ksrPJ/psEDzOFSz
/bdoyNrGj1E8svuR3Bznm53htw1yj+KkxKl4+esUrMZDBcJlOSgYAsOCsp0FvmXt
ll9ldDz7CTUue5wT/RsPXcdtgTpWD8w74a8CLyKsRspGPKAcTNZEtF4uXBVmCeEm
Kf7GUmG6sXP/wwyc5WxqlD8UykAWlYTzWamsX0xhk23RO8yilQwipmdnRC652dKK
QbNmC1r7fSOl8hqw/96bg5Qu0T/fkreRrwU7ZcegbLHNYhLDkBvjJc40vG93drEQ
w/cFGsDWr3RiSBd3kmmQYRzelYB0VI8YHMPzA9C/pEN1hlMYegouCRw2n5H9gooi
S9EOUCXdywMMF8mDAAhONU2Ki+3wApRmLER/y5UnlhetCTCstnEXbosX9hwJ1C07
mKVx01QT2WDz9UtmT/rx7iASjbSsV7FFY6GsdqnC+w==
-----END CERTIFICATE-----
Certificate bag
Bag Attributes
    friendlyName: wile e coyote
    localKeyID: 54 69 6D 65 20 31 36 35 39 38 30 32 39 34 31 36 33 32 
subject=C = CA, ST = Wileshire, L = Wilewood, O = "ACME, INC.", CN = Wile E Coyote
issuer=C = CA, ST = Wileshire, L = Wilewood, O = "ACME, INC.", CN = Wile E Coyote
-----BEGIN CERTIFICATE-----
MIIEtTCCA52gAwIBAgIEYu6UxDANBgkqhkiG9w0BAQsFADBhMQswCQYDVQQGEwJD
QTESMBAGA1UECAwJV2lsZXNoaXJlMREwDwYDVQQHDAhXaWxld29vZDETMBEGA1UE
CgwKQUNNRSwgSU5DLjEWMBQGA1UEAwwNV2lsZSBFIENveW90ZTAeFw0yMjA4MDYx
NjIwMjBaFw0yMzA4MDYxNjIwMjBaMGExCzAJBgNVBAYTAkNBMRIwEAYDVQQIDAlX
aWxlc2hpcmUxETAPBgNVBAcMCFdpbGV3b29kMRMwEQYDVQQKDApBQ01FLCBJTkMu
MRYwFAYDVQQDDA1XaWxlIEUgQ295b3RlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
MIIBCgKCAQEAj9fEnZDuzi9SN4XrnSK5HubQnLXYBCZDg0jCutGojOlxis0QRja7
3OdM6db18YDOzCbHsEEi5pbvUBLRLoKImbIQKBZuf1F/081WtXMZ3Rehqil04Hkm
1lLibBuHcr3PHL1kvqmW6pASqx/05M0Ol9RzK1YeXHCqqSU6/KK6LyTtB/5mZ9n9
OYY1WlMh1aBAqrEj2Lj/as504ff/i0FDf0BuboaFM3tdAPA1kHqvM33q061Jt2JF
7EVoQaSe+LVx4qjo8AY0kfZ7F0T2QSBnkh0GSmpi4yk3JUoYuiyLQxwKAMhQ/jXV
Mo28LmRz24P30CfHIpglSbkQOek2cg4WlQIDAQABo4IBczCCAW8wEgYDVR0TAQH/
BAgwBgEB/wIBATCBjgYDVR0jBIGGMIGDgBT/syDWAnGiDVY7t++q1mLljCkMb6Fl
pGMwYTELMAkGA1UEBhMCQ0ExEjAQBgNVBAgMCVdpbGVzaGlyZTERMA8GA1UEBwwI
V2lsZXdvb2QxEzARBgNVBAoMCkFDTUUsIElOQy4xFjAUBgNVBAMMDVdpbGUgRSBD
b3lvdGWCBGLulMQwHQYDVR0OBBYEFP+zINYCcaINVju376rWYuWMKQxvMAwGA1Ud
DwQFAwMH/4AwgZoGA1UdJQSBkjCBjwYIKwYBBQUHAwEGCCsGAQUFBwMCBggrBgEF
BQcDAwYKKwYBBAGCNwoDDAYJKoZIhvcvAQEFBggrBgEFBQcDBAYKKwYBBAGCNwoD
BAYIKwYBBQUHAwUGCCsGAQUFBwMGBggrBgEFBQcDBwYIKwYBBQUHAwgGCCsGAQUF
BwMJBgorBgEEAYI3FAICBgRVHSUAMA0GCSqGSIb3DQEBCwUAA4IBAQAW02o5QNdq
Rwd5te62ZW4dslBwO6ibzY1FtSqwC9ZUk0Mpfk2OMaM1jIePG0y0Sw4RKDBp+oH1
LMcN4AgrnOEVA87xwoOJrtZ8EGtSbYF/UQVZR0jXLV7f/Xr7XiDBh0lnsMlQKAu8
P8Y+hgY/lEKJ/Kb2uUz/ci3ZkTlu5XqOQmi3ChwcAMPLR3XCPP9NgAv3jhv/OvSF
7CC3FFndvnQmb1OMpndYh9foJzgFReVEMk0DKRa/1Xz1GNsjHJNpEEOdwo1qEuN/
/mfhK4REoKOunLGlI3vMjXKrD/V0JYAWASYDng7FrUHec4glOqwiQI/T4du6dvQf
SLUzQIGHRMDH
-----END CERTIFICATE-----
OPENSSL_END
if ($major eq '1.0') {
  $openssl_output =~ s/MAC: sha1, Iteration 10000/MAC Iteration 10000/g;
  $openssl_output =~ s/MAC length: .*/MAC verified OK/;
}
if ($major ge '3.2') {
  $openssl_output =~ s/2.16.840.1.113894.746875.1.1/Trusted key usage (Oracle)/g;
}

my $pass   = "1234";
my $pkcs12 = Crypt::OpenSSL::PKCS12->new_from_file('certs/test.pfx');

my $info = $pkcs12->info($pass);

ok(sha256_hex($info) eq sha256_hex($openssl_output), "Output matches OpenSSL");

my $info_hash = $pkcs12->info_as_hash($pass);

if ($major gt '1.0') {
  like($info_hash->{mac}{digest}, qr/sha1/, "MAC Digest is sha1");
  like($info_hash->{mac}{length}, qr/20/, "MAC length is 20");
  like($info_hash->{mac}{salt_length}, qr/20/, "MAC salt_length is 20");
}

like($info_hash->{mac}{iteration}, qr/10000/, "MAC Iteration is 10000");

my $pkcs7_cnt = scalar @{$info_hash->{pkcs7_data}};
ok($info_hash->{pkcs7_data}, "pkcs7_data key exists");

for (my $i = 0; $i < $pkcs7_cnt; $i++) {
  my $bags = $info_hash->{pkcs7_data}[$i]->{bags};

  is(scalar @$bags, 1, "One bag in pkcs7_data");
  ok($info_hash->{pkcs7_data}, "  pkcs7_data key exists");

  my $bag_attributes = @$bags[0]->{bag_attributes};

  is(keys %$bag_attributes, 2, "  Two bag attributes in pkcs7_data bag");

  foreach my $attribute (keys %$bag_attributes) {
        like($bag_attributes->{localKeyID}, qr/54 69 6D 65 20 31 36 35 39 38 30 32 39 34 31 36 33 32/, "    localKeyID matches") if $attribute eq "localKeyID";
        like($bag_attributes->{friendlyName}, qr/wile e coyote/, "    friendlyName matches") if $attribute eq "friendlyName";
  }

  like(@$bags[0]->{key}, qr/PRIVATE KEY/, "  pkcs7_data found private key");
  like(@$bags[0]->{key}, qr/BZZIiuzTSzWhQtdkFcgFD0S7hnSZ/, "  pkcs7_data key matches");
  like(@$bags[0]->{parameters}->{iteration}, qr/10000/, "  pkcs7_data parameters iteration matches");
  like(@$bags[0]->{parameters}->{nid_long_name}, qr/PBKDF2/, "  pkcs7_data parameters nid_long_name matches");
  like(@$bags[0]->{parameters}->{nid_short_name}, qr/PBKDF2/, "  pkcs7_bag parameters nid_short_name matches");
  like(@$bags[0]->{type}, qr/shrouded_keybag/, "  pkcs7_data bag type matches");
}

my $pkcs7_enc_cnt = scalar @{$info_hash->{pkcs7_encrypted_data}};
ok($info_hash->{pkcs7_encrypted_data}, "pkcs7_encrypted_data key exists");

for (my $i = 0; $i < $pkcs7_enc_cnt; $i++) {
  my $bags = $info_hash->{pkcs7_encrypted_data}[$i]->{bags};

  is(scalar @$bags, 2, "Two bags in pkcs7_encrypted_data");
  ok($info_hash->{pkcs7_encrypted_data}, "  pkcs7_encrypted_data key exists");

  my $bag_attributes = @$bags[0]->{bag_attributes};

  my $parameters = $info_hash->{pkcs7_encrypted_data}[$i]->{parameters};
  like($parameters->{iteration}, qr/10000/, "  pkcs7_encrypted_data parameters iteration matches");
  like($parameters->{nid_long_name}, qr/PBKDF2/, "  pkcs7_encrypted_data parameters nid_long_name matches");
  like($parameters->{nid_short_name}, qr/PBKDF2/, "  pkcs7_encrypted_bag parameters nid_short_name matches");

  like(@$bags[0]->{cert}, qr/CERTIFICATE/, "pkcs7_encrypted_data found certificate");

  my $num = 2;
  if ($major ge '3.1') {
      $num = 2;
  }
  is(keys %$bag_attributes, $num, "  Number of bag attributes in bag match");
  foreach my $attribute (keys %$bag_attributes) {
        like($bag_attributes->{'Trusted key usage (Oracle)'}, qr/<Unsupported tag 6>/, "    Trusted key usage (Oracle) matches") if $attribute eq "Trusted key usage (Oracle)";
        like($bag_attributes->{friendlyName}, qr/ssl.com ev root certification authority rsa r2/, "    friendlyName matches") if $attribute eq "friendlyName";
  }

  like(@$bags[0]->{cert}, qr/VSbooi4iTsjQc2KRVbrcc0N6ZVTsj9CLg/, "  pkcs7_encrypted_data key matches");
  like(@$bags[0]->{type}, qr/certificate_bag/, "  pkcs7_encrypted_data bag type matches");

  like(@$bags[0]->{issuer}, qr/C = US, ST = Texas, L = Houston, O = SSL Corporation, CN = SSL.com EV Root Certification Authority RSA R2/, "  pkcs7_encrypted_data issuer matches");
  like(@$bags[0]->{subject}, qr/C = US, ST = Texas, L = Houston, O = SSL Corporation, CN = SSL.com EV Root Certification Authority RSA R2/, "  pkcs7_encrypted_data subject matches");

  $bag_attributes = @$bags[1]->{bag_attributes};

  like(@$bags[1]->{cert}, qr/CERTIFICATE/, "pkcs7_encrypted_data found certificate");

  is(keys %$bag_attributes, 2, "  Two bag attributes in bag");
  foreach my $attribute (keys %$bag_attributes) {
        like($bag_attributes->{localKeyID}, qr/54 69 6D 65 20 31 36 35 39 38 30 32 39 34 31 36 33 32/, "    localKeyID matches") if $attribute eq "localKeyID";
        like($bag_attributes->{friendlyName}, qr/wile e coyote/, "friendlyName matches") if $attribute eq "    friendlyName";
  }

  like(@$bags[1]->{cert}, qr/IBATCBjgYDVR0jBIGGMIGDgBT/, "  pkcs7_encrypted_data key matches");
  like(@$bags[1]->{type}, qr/certificate_bag/, "  pkcs7_encrypted_data bag type matches");

  like(@$bags[1]->{issuer}, qr/C = CA, ST = Wileshire, L = Wilewood, O = "ACME, INC.", CN = Wile E Coyote/, "  pkcs7_encrypted_data issuer matches");
  like(@$bags[1]->{subject}, qr/C = CA, ST = Wileshire, L = Wilewood, O = "ACME, INC.", CN = Wile E Coyote/, "  pkcs7_encrypted_data subject matches");
}
done_testing;
