use strict;
use warnings;
use Test::More;
use Digest::SHA qw/sha256_hex/;
use Crypt::OpenSSL::Guess qw/openssl_version/;

my ($major, $minor, $patch) = openssl_version();
BEGIN { use_ok('Crypt::OpenSSL::PKCS12') };
my $openssl_output =<< 'OPENSSL_END';
MAC: sha1, Iteration 2048
MAC length: 20, salt length: 8
PKCS7 Encrypted data: pbeWithSHA1And40BitRC2-CBC, Iteration 2048
Certificate bag
Bag Attributes: <No Attributes>
subject=C = US, O = National Aeronautics and Space Administration, serialNumber = 16 + CN = Steve Schoch
issuer=C = US, O = National Aeronautics and Space Administration
-----BEGIN CERTIFICATE-----
MIICjTCCAfigAwIBAgIEMaYgRzALBgkqhkiG9w0BAQQwRTELMAkGA1UEBhMCVVMx
NjA0BgNVBAoTLU5hdGlvbmFsIEFlcm9uYXV0aWNzIGFuZCBTcGFjZSBBZG1pbmlz
dHJhdGlvbjAmFxE5NjA1MjgxMzQ5MDUrMDgwMBcROTgwNTI4MTM0OTA1KzA4MDAw
ZzELMAkGA1UEBhMCVVMxNjA0BgNVBAoTLU5hdGlvbmFsIEFlcm9uYXV0aWNzIGFu
ZCBTcGFjZSBBZG1pbmlzdHJhdGlvbjEgMAkGA1UEBRMCMTYwEwYDVQQDEwxTdGV2
ZSBTY2hvY2gwWDALBgkqhkiG9w0BAQEDSQAwRgJBALrAwyYdgxmzNP/ts0Uyf6Bp
miJYktU/w4NG67ULaN4B5CnEz7k57s9o3YY3LecETgQ5iQHmkwlYDTL2fTgVfw0C
AQOjgaswgagwZAYDVR0ZAQH/BFowWDBWMFQxCzAJBgNVBAYTAlVTMTYwNAYDVQQK
Ey1OYXRpb25hbCBBZXJvbmF1dGljcyBhbmQgU3BhY2UgQWRtaW5pc3RyYXRpb24x
DTALBgNVBAMTBENSTDEwFwYDVR0BAQH/BA0wC4AJODMyOTcwODEwMBgGA1UdAgQR
MA8ECTgzMjk3MDgyM4ACBSAwDQYDVR0KBAYwBAMCBkAwCwYJKoZIhvcNAQEEA4GB
AH2y1VCEw/A4zaXzSYZJTTUi3uawbbFiS2yxHvgf28+8Js0OHXk1H1w2d6qOHH21
X82tZXd/0JtG0g1T9usFFBDvYK8O0ebgz/P5ELJnBL2+atObEuJy1ZZ0pBDWINR3
WkDNLCGiTkCKp0F5EWIrVDwh54NNevkCQRZita+z4IBO
-----END CERTIFICATE-----
Certificate bag
Bag Attributes: <No Attributes>
subject=emailAddress = cooke@issl.atl.hp.com, C = US, OU = Hewlett Packard Company (ISSL), CN = Paul A. Cooke
issuer=C = Ca, L = Nepean, OU = No Liability Accepted, O = For Demo Purposes Only, CN = Entrust Demo Web CA
-----BEGIN CERTIFICATE-----
MIICiTCCAfKgAwIBAgIEMeZfHzANBgkqhkiG9w0BAQQFADB9MQswCQYDVQQGEwJD
YTEPMA0GA1UEBxMGTmVwZWFuMR4wHAYDVQQLExVObyBMaWFiaWxpdHkgQWNjZXB0
ZWQxHzAdBgNVBAoTFkZvciBEZW1vIFB1cnBvc2VzIE9ubHkxHDAaBgNVBAMTE0Vu
dHJ1c3QgRGVtbyBXZWIgQ0EwHhcNOTYwNzEyMTQyMDE1WhcNOTYxMDEyMTQyMDE1
WjB0MSQwIgYJKoZIhvcNAQkBExVjb29rZUBpc3NsLmF0bC5ocC5jb20xCzAJBgNV
BAYTAlVTMScwJQYDVQQLEx5IZXdsZXR0IFBhY2thcmQgQ29tcGFueSAoSVNTTCkx
FjAUBgNVBAMTDVBhdWwgQS4gQ29va2UwXDANBgkqhkiG9w0BAQEFAANLADBIAkEA
6ceSq9a9AU6g+zBwaL/yVmW1/9EE8s5you1mgjHnj0wAILuoB3L6rm6jmFRy7QZT
G43IhVZdDua4e+5/n1ZslwIDAQABo2MwYTARBglghkgBhvhCAQEEBAMCB4AwTAYJ
YIZIAYb4QgENBD8WPVRoaXMgY2VydGlmaWNhdGUgaXMgb25seSBpbnRlbmRlZCBm
b3IgZGVtb25zdHJhdGlvbiBwdXJwb3Nlcy4wDQYJKoZIhvcNAQEEBQADgYEAi8qc
F3zfFqy1sV8NhjwLVwOKuSfhR/Z8mbIEUeSTlnH3QbYt3HWZQ+vXI8mvtZoBc2Fz
lexKeIkAZXCesqGbs6z6nCt16P6tmdfbZF3I3AWzLquPcOXjPf4HgstkyvVBn0Ap
jAFN418KF/Cx4qyHB4cjdvLrRjjQLnb2+ibo7QU=
-----END CERTIFICATE-----
OPENSSL_END
if ($major eq '1.0') {
  $openssl_output =~ s/MAC: sha1, Iteration 2048/MAC Iteration 2048/g;
  $openssl_output =~ s/MAC length: .*/MAC verified OK/;
}
my $pass   = "v3-certs";
my $pkcs12 = Crypt::OpenSSL::PKCS12->new_from_file('certs/v3-certs-RC2.p12');

my $info = $pkcs12->info($pass);
ok(sha256_hex($info) eq sha256_hex($openssl_output), "Output matches OpenSSL");

my $info_hash = $pkcs12->info_as_hash($pass);

if ($major gt '1.0') {
  like($info_hash->{mac}{digest}, qr/sha1/, "MAC Digest is sha1");
  like($info_hash->{mac}{length}, qr/20/, "MAC length is 20");
  like($info_hash->{mac}{salt_length}, qr/8/, "MAC salt_length is 8");
}

like($info_hash->{mac}{iteration}, qr/2048/, "MAC Iteration is 2048");

my $pkcs7_enc_cnt = scalar @{$info_hash->{pkcs7_encrypted_data}};
ok($info_hash->{pkcs7_encrypted_data}, "pkcs7_encrypted_data key exists");

for (my $i = 0; $i < $pkcs7_enc_cnt; $i++) {

  my $bags = $info_hash->{pkcs7_encrypted_data}[0]->{bags};

  is(scalar @$bags, 2, "Two bags in pkcs7_encrypted_data");
  ok($info_hash->{pkcs7_encrypted_data}, "pkcs7_encrypted_data key exists");

  my $bag_attributes = @$bags[0]->{bag_attributes};

  is(keys %$bag_attributes, 0, "No bag attributes in bag");

  my $parameters = $info_hash->{pkcs7_encrypted_data}[$i]->{parameters};
  like($parameters->{iteration}, qr/2048/, "pkcs7_data parameters iteration matches");
  like($parameters->{nid_long_name}, qr/pbeWithSHA1And40BitRC2-CBC/, "pkcs7_data parameters nid_long_name matches");
  like($parameters->{nid_short_name}, qr/PBE-SHA1-RC2-40/, "pkcs7_bag parameters nid_short_name matches");

  like(@$bags[0]->{cert}, qr/CERTIFICATE/, "pkcs7_encrypted_data found certificate 0");
  like(@$bags[0]->{cert}, qr/NjA0BgNVBAoTLU5hdGlvbmFsIEFlcm9uYX/, "pkcs7_encrypted_data key matches");
  like(@$bags[0]->{type}, qr/certificate_bag/, "pkcs7_encrypted_data bag type matches");

  like(@$bags[0]->{issuer}, qr/C = US, O = National Aeronautics and Space Administration/, "pkcs7_encrypted_data issuer matches");
  like(@$bags[0]->{subject}, qr/C = US, O = National Aeronautics and Space Administration, serialNumber = 16 \+ CN = Steve Schoch/, "pkcs7_encrypted_data subject matches");

  like(@$bags[1]->{cert}, qr/CERTIFICATE/, "pkcs7_encrypted_data found certificate 1");
  like(@$bags[1]->{cert}, qr/dWwgQS4gQ29va2UwXDANBgkqhkiG9w0B/, "pkcs7_encrypted_data key matches");
  like(@$bags[1]->{type}, qr/certificate_bag/, "pkcs7_encrypted_data bag type matches");

  like(@$bags[1]->{issuer}, qr/C = Ca, L = Nepean, OU = No Liability Accepted, O = For Demo Purposes Only, CN = Entrust Demo Web CA/, "pkcs7_encrypted_data issuer matches");
  like(@$bags[1]->{subject}, qr/emailAddress = cooke\@issl.atl.hp.com, C = US, OU = Hewlett Packard Company \(ISSL\), CN = Paul A. Cooke/, "pkcs7_encrypted_data subject matches");


  $bag_attributes = @$bags[1]->{bag_attributes};
  is(keys %$bag_attributes, 0, "Zero bag attributes in bag");
}
done_testing;
