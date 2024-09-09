use strict;
use warnings;
use Test::More;
use Digest::SHA qw/sha256_hex/;
use Crypt::OpenSSL::Guess qw/openssl_version/;

my ($major, $minor, $patch) = openssl_version();
BEGIN { use_ok('Crypt::OpenSSL::PKCS12') };
my $openssl_output =<< 'OPENSSL_END';
MAC: sha256, Iteration 2048
MAC length: 32, salt length: 8
PKCS7 Encrypted data: PBES2, PBKDF2, AES-256-CBC, Iteration 2048, PRF hmacWithSHA256
Certificate bag
Bag Attributes
    localKeyID: B2 36 02 16 22 C6 18 EF B1 5B D0 69 DB CD 25 B9 89 62 5D 94 
subject=C = CA, ST = New Brunswick, L = Moncton, O = Crypt::OpenSSL::PKCS12, CN = Crypt::OpenSSL::PKCS12
issuer=C = CA, ST = New Brunswick, L = Moncton, O = Crypt::OpenSSL::PKCS12, CN = Crypt::OpenSSL::PKCS12
-----BEGIN CERTIFICATE-----
MIIF0zCCA7ugAwIBAgIUNRGGesA4c//y3afo9bFyNDSNF18wDQYJKoZIhvcNAQEL
BQAweTELMAkGA1UEBhMCQ0ExFjAUBgNVBAgMDU5ldyBCcnVuc3dpY2sxEDAOBgNV
BAcMB01vbmN0b24xHzAdBgNVBAoMFkNyeXB0OjpPcGVuU1NMOjpQS0NTMTIxHzAd
BgNVBAMMFkNyeXB0OjpPcGVuU1NMOjpQS0NTMTIwHhcNMjQwNjI4MTU0MjQ3WhcN
MjUwNjI4MTU0MjQ3WjB5MQswCQYDVQQGEwJDQTEWMBQGA1UECAwNTmV3IEJydW5z
d2ljazEQMA4GA1UEBwwHTW9uY3RvbjEfMB0GA1UECgwWQ3J5cHQ6Ok9wZW5TU0w6
OlBLQ1MxMjEfMB0GA1UEAwwWQ3J5cHQ6Ok9wZW5TU0w6OlBLQ1MxMjCCAiIwDQYJ
KoZIhvcNAQEBBQADggIPADCCAgoCggIBAOZ2wKuOP7kl3x8JRcyV45+yDYg1NDGv
tcCrfB4hIYU8dKrz2iq8f11nPEYb8o5Od1O7n8IQd3ERZRFonFDMHmURzehlFf+4
ee3uxVP4eW4UvbUOLWfU/DCzeN63V3FgF3ZGSJinccQoebG1uWghmwcQC9QlHPMH
knJCxlWwyFsM3DeRG5r/Cs1di6LlcOlEibIabQdReK4iM4vMhhcALlvq2SbT/Lsn
XIJfb+kyfQScIB0MagYv+Nt7n8WJzp30ggL25wYq4GsMYaLFPR6YKByts2GSrsMt
OTjmB2qRpFgITpL6ENuBQhnv6awPMwMno/oC3C4RUygEo0PUeWQPuwd+Xl8YpwvD
ulwxmkovuBNA0mKqoOZzHIfAX/DxR+RPTJvwCChWxYw2gf6v0rBKyz/9j0JK+mx8
M+fItTZJ2IgEtzQ1wilMATukdCK+TsCDPv2aMHru48RUK/i9W7pmM9w2UUy8C4v+
r4SNudUvePRBO8dEcNyGrN/zJ3Satl3TnHOqM6yXT0+MobG8IERZT1TaxdQYdYQ4
xXm6+CIM+IpIJzvebHLfnM/qnL5GJsJzoq2oLyVHt7Kd3xZLk0bQlctBYiO14CNS
7Ekp5y1DLMV4GZUxVvVH1yMPNfCXYPf+ETfztpHvqxYGKqngBnXPDmWOkV21fgzz
jUdqMZRZErBfAgMBAAGjUzBRMB0GA1UdDgQWBBRUgzUE+MNLWBDGElOMrodFU8gq
/zAfBgNVHSMEGDAWgBRUgzUE+MNLWBDGElOMrodFU8gq/zAPBgNVHRMBAf8EBTAD
AQH/MA0GCSqGSIb3DQEBCwUAA4ICAQAcVL0ZoHyXHHPy2W2bLSwqMjGZ0HOo3Jdk
PQG5BQS6kRDFJHnrH1d5x3liz/7w8BguQzWHlggMBGTeU5YxiBefcHvZQKsGhg/Q
7rLnMHXn0ikCYRzopZezDcGKWL2Ty+ItodzkPFZdInPWWIu5qlNRJ2G32DKKgcr+
dXkLKzbkZ0G/sNrfgWNW5eNFeWx4KhzWwzubkpcAAZ21xWQDtRFL3MTouwxbovcv
UCPS/o7DvQ7hc1+OeZ3JgFK4L4gVSO0G2n7Q4nKKQrQDSpTixpx5TVzB9vFUlXwV
E2J5Ntu3ohpTw2zZ/sCFxvhboXR0hLSsRI7WWKNSiaVX4RzgRrCdCmLO8HtsXtmg
XLSTDllwrCv7I3lEghF1p56vkAZ5WvGvlT5tAHWz+dthnbdmiPGOPSZXkQ1DOJIV
EDWRwagYAaeBHbjY4NzMqF7tYeSXBRLV8MRaHyyg2TwMPzU7TQQKWbWZG6CRpEaU
zVi2Y0/1FJG3GyA3CzutsPxrW6jxPjsu6elwyn4of5p88yi+0KbtKkb4UyZWlyhQ
EINLXwrOUZrpRcx4Wf2CUZQI3cF0NQjM0olV4vfyZ+L4daYxSTWoBBLghRJjRgvJ
NZ8n9AVdOXVgHMUWqs4ODvtyLukhVdeuyVMcEiIxf2TRs4VARvttrwTPJriDCGrO
eoO/3d59Kg==
-----END CERTIFICATE-----
PKCS7 Data
Key bag
Bag Attributes
    localKeyID: B2 36 02 16 22 C6 18 EF B1 5B D0 69 DB CD 25 B9 89 62 5D 94 
Key Attributes: <No Attributes>
-----BEGIN PRIVATE KEY-----
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
4U5P3ZCBWZcIHhRZJ3R1KYinfNU3gNI=
-----END PRIVATE KEY-----
OPENSSL_END
if ($major eq '1.0') {
  $openssl_output =~ s/MAC: sha.*, Iteration 2048/MAC Iteration 2048/g;
  $openssl_output =~ s/MAC length: .*/MAC verified OK/;
}

my $pass   = "testing";
my $pkcs12 = Crypt::OpenSSL::PKCS12->new_from_file('certs/keyStore.p12');

my $info = $pkcs12->info($pass);

ok(sha256_hex($info) eq sha256_hex($openssl_output), "Output matches OpenSSL");

my $info_hash = $pkcs12->info_as_hash($pass);

if ($major gt '1.0') {
  like($info_hash->{mac}{digest}, qr/sha256/, "MAC Digest is sha256");
  like($info_hash->{mac}{length}, qr/32/, "MAC length is 32");
  like($info_hash->{mac}{salt_length}, qr/8/, "MAC salt_length is 8");
}

like($info_hash->{mac}{iteration}, qr/2048/, "MAC Iteration is 2048");
my $pkcs7_cnt = scalar @{$info_hash->{pkcs7_data}};
ok($info_hash->{pkcs7_data}, "pkcs7_data key exists");

  my $bags = $info_hash->{pkcs7_encrypted_data}[0]->{bags};

  is(scalar @$bags, 1, "One key_bag in pkcs7_data");

  my $bag_attributes = @$bags[0]->{bag_attributes};

  is(keys %$bag_attributes, 1, "One bag attributes in bag");
  foreach my $attribute (keys %$bag_attributes) {
        like($bag_attributes->{localKeyID}, qr/B2 36 02 16 22 C6 18 EF B1 5B D0 69 DB CD 25 B9 89 62 5D 94/, "localKeyID matches") if $attribute eq "localKeyID";
  }

  like(@$bags[0]->{cert}, qr/CERTIFICATE/, "pkcs7_encrypted_data found certificate 0");
  like(@$bags[0]->{cert}, qr/gIPADCCAgoCggIBAOZ2wKuOP7kl3x8/, "pkcs7_encrypted_data key matches");
  like(@$bags[0]->{type}, qr/certificate_bag/, "pkcs7_encrypted_data bag type matches");

  like(@$bags[0]->{issuer}, qr/C = CA, ST = New Brunswick, L = Moncton, O = Crypt::OpenSSL::PKCS12, CN = Crypt::OpenSSL::PKCS12/, "pkcs7_encrypted_data issuer matches");
  like(@$bags[0]->{subject}, qr/C = CA, ST = New Brunswick, L = Moncton, O = Crypt::OpenSSL::PKCS12, CN = Crypt::OpenSSL::PKCS12/, "pkcs7_encrypted_data subject matches");

  $bags = $info_hash->{pkcs7_data}[0]->{bags};

  like(@$bags[0]->{key}, qr/PRIVATE KEY/, "pkcs7_data found private key");
  like(@$bags[0]->{key}, qr/dKX2tYb0gY5lD00kbGZBbJlb9bWGowav/, "pkcs7_data key matches");
  like(@$bags[0]->{type}, qr/key_bag/, "pkcs7_data bag type matches");

  $bag_attributes = @$bags[0]->{bag_attributes};

  is(keys %$bag_attributes, 1, "One bag attributes in bag");
  foreach my $attribute (keys %$bag_attributes) {
        like($bag_attributes->{localKeyID}, qr/B2 36 02 16 22 C6 18 EF B1 5B D0 69 DB CD 25 B9 89 62 5D 94/, "localKeyID matches") if $attribute eq "localKeyID";
  }

done_testing;
