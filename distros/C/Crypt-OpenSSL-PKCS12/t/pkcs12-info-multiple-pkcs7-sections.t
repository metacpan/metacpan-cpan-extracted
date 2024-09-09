use strict;
use warnings;
use Test::More;
use Digest::SHA qw/sha256_hex/;
use Crypt::OpenSSL::Guess qw/openssl_version/;

my ($major, $minor, $patch) = openssl_version();
BEGIN { use_ok('Crypt::OpenSSL::PKCS12') };
my $openssl_output =<< 'OPENSSL_END';
MAC: sha1, Iteration 2000
MAC length: 20, salt length: 20
PKCS7 Data
Shrouded Keybag: pbeWithSHA1And3-KeyTripleDES-CBC, Iteration 2000
Bag Attributes
    localKeyID: 01 00 00 00 
    friendlyName: 3f71af65-1687-444a-9f46-c8be194c3e8e
    Microsoft CSP Name: Microsoft Enhanced Cryptographic Provider v1.0
Key Attributes
    X509v3 Key Usage: 10 
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC8trBCTBjXXA4O
gSO5nRTOU5T86ObCgc71J2oCuUigSddcTDzebaD0wcyAgf101hAdwMKQ9DvrK0nG
vm7FAMnnUuVeATafKgshLuUTUUfKjx4Xif4LoS0/ev4BiOI5a1MlIRZ7T5Cyjg8b
vuympzMuinQ/j1RPLIV0VGU2HuDxuuP3O898GqZ3+F6Al5CUcwmOX9zCs91JdN/Z
FZ05SXIpHQuyPSPUX5Vy8F1ZeJ8VG3nkbemfFlVkuKQqvteL9mlT7z95rVZgGB3n
UZL0tOB68eMcffA9zUksOmeTi5M6jnBcNeX2Jh9jS3YYd+IEliZmmggQG7kPta8f
+NqezL77AgMBAAECggEAXPu5GlmLbeW+SVhJJYZn/4fAY+NP/GvgcPv0KJZp2gy4
MBKidUhYI/Evlew22fA1ratSUwD8WxIPvn0LcEdEtJWsTWbUppUdOcL0/VExyfU9
swR7p/hJJruv10q+iONAaw2EGcso9Um42Qd4bF77AYYX5E93j7FUqm6BFisd1AzU
rF69l6lbyuJBhi73ZaAD2etQrdCCPp/ZCAGCEohkCf+qccH02bHdy03ZBTMjpEyB
/dLPJmIO8BpTrXMOLoGVzhuryCcL7dIc5YVgfNOy71eK1ZrTuv0pkl8ENJ8jGueZ
m61BXyO1z0xfYMxyEt0vuER2QIEk+jIluM+1EGV86QKBgQDnjhQzHWS/xmsEQJYg
NBtqCx8HYkMjLcHklm+sTfm6iMiu5AnjGN6XG9rWAWnGmGIrVy7ozMaTc1nVujsP
f2y3VjzjOHaWJ5erKuM3bfZ+TAJeHbXyrIUBHgUKCd9NZXyx3k5V0kZD3ncWRV0Z
1WW7RUFKyJWcj6nYkORS7dQnmQKBgQDQostbApgUxp2rLGBiqyE0/NQVV0xRc9Xl
7orDl33B37LarfBaeQYTyZV9C5/+IwEC5vdmUcTSFiUtWEMHvYP9IAIjdiUjflNL
NQKvr6I62nEFvL/am4GOJQ9BhBTFY9bRGZ+F3NMzgVsT7ThahlhZnTuPnp2Ht38C
d55U7crnswKBgEZJLT56vJstqkxHIoqx5mRg7dE69XAXMpSlSU5++L+zR1823v1t
DhvGG737/dSHar0HILkPd3NIf0tN1SGWJzTbW24JNI3NhM8zHHc1zK13evyAfjsk
PNci+pqadoqytI/1D8gjJKrzOyiqc2ElElUu52vAyREV1pNjH7tAb7Z5AoGBAJAi
p5KsbByOSobjFYOU7lAJCwvjT5pGCFPdRIhztDGoNYvV9uLKEWTCM0A8M8ACtsQm
hGxvuSXanryA6W4Dg5fv8QpGqMmokCq46K4vDEjUeJiaGYERRaPJ/owoj6D+pH24
0fhM4qwGhcFydSg0//yJH4jM78+++UPfF8dcsHz5AoGASzcgf+BzR2c4j3i51OJQ
xoy9KLJ7KYzYRZoQ9O0T0Gkzg5jS2NSVQ2qALkRq/XI1uYEH+k5P6sUCR08NHkjT
lP0pgHHA4M3xpj3qf0tvTFrAnDuVdpx97vLB2R1JqmwztBx6o2os0NBot47j/hp6
9xZcVA0VYoArSVZ58z+zYrA=
-----END PRIVATE KEY-----
PKCS7 Data
Certificate bag
Bag Attributes
    localKeyID: 01 00 00 00 
subject=CN = anonymous
issuer=CN = anonymous
-----BEGIN CERTIFICATE-----
MIIDCTCCAfGgAwIBAgIQNu32hzqhCKdHATXzboyIETANBgkqhkiG9w0BAQUFADAU
MRIwEAYDVQQDEwlhbm9ueW1vdXMwIBcNMTYwNzE5MjIwMDAxWhgPMjExNjA2MjUy
MjAwMDFaMBQxEjAQBgNVBAMTCWFub255bW91czCCASIwDQYJKoZIhvcNAQEBBQAD
ggEPADCCAQoCggEBALy2sEJMGNdcDg6BI7mdFM5TlPzo5sKBzvUnagK5SKBJ11xM
PN5toPTBzICB/XTWEB3AwpD0O+srSca+bsUAyedS5V4BNp8qCyEu5RNRR8qPHheJ
/guhLT96/gGI4jlrUyUhFntPkLKODxu+7KanMy6KdD+PVE8shXRUZTYe4PG64/c7
z3wapnf4XoCXkJRzCY5f3MKz3Ul039kVnTlJcikdC7I9I9RflXLwXVl4nxUbeeRt
6Z8WVWS4pCq+14v2aVPvP3mtVmAYHedRkvS04Hrx4xx98D3NSSw6Z5OLkzqOcFw1
5fYmH2NLdhh34gSWJmaaCBAbuQ+1rx/42p7MvvsCAwEAAaNVMFMwFQYDVR0lBA4w
DAYKKwYBBAGCNwoDBDAvBgNVHREEKDAmoCQGCisGAQQBgjcUAgOgFgwUYW5vbnlt
b3VzQHdpbmRvd3MteAAwCQYDVR0TBAIwADANBgkqhkiG9w0BAQUFAAOCAQEAuH7i
qY0/MLozwFb39ILYAJDHE+HToZBQbHQP4YtienrUStk60rIp0WH65lam7m/JhgAc
Itc/tV1L8mEnLrvvKcA+NeIL8sDOtM28azvgcOi0P3roeLLLRCuiykUaKmUcZEDm
9cDYKIpJf7QetWQ3uuGTk9iRzpH79x2ix35BnyWQRr3INZzmX/+9YRvPBXKYl/89
F/w1ORYArpI9XtjfuPWaGQmM4f1WRHE2t3qRyKFFri7QiZdpcSx5zvsRHSyjfUMo
Ks+b6upk+P01lIhg/ewwYngGab+fZhF15pTNN2hx8PdNGcrGzrkNKCmJKrWCa2xc
zuMA+z8SCuC1tYTKmA==
-----END CERTIFICATE-----
OPENSSL_END
if ($major eq '1.0') {
  $openssl_output =~ s/MAC: sha1, Iteration 2000/MAC Iteration 2000/g;
  $openssl_output =~ s/MAC length: .*/MAC verified OK/;
}

SKIP: {

    skip ("Pre OpenSSL 1.1.0 release does not support utf8 passwords", 20) if ($major le '1.0');


my $pass   = "σύνθημα γνώρισμα";
my $pkcs12 = Crypt::OpenSSL::PKCS12->new_from_file('certs/shibboleth.pfx');

my $info = $pkcs12->info($pass);
ok(sha256_hex($info) eq sha256_hex($openssl_output), "Output matches OpenSSL");

my $info_hash = $pkcs12->info_as_hash($pass);

if ($major gt '1.0') {
  like($info_hash->{mac}{digest}, qr/sha1/, "MAC Digest is sha1");
  like($info_hash->{mac}{length}, qr/20/, "MAC length is 20");
  like($info_hash->{mac}{salt_length}, qr/20/, "MAC salt_length is 20");
}

like($info_hash->{mac}{iteration}, qr/2000/, "MAC Iteration is 2000");

my $pkcs7_cnt = scalar @{$info_hash->{pkcs7_data}};
ok($info_hash->{pkcs7_data}, "pkcs7_data key exists");

for (my $i = 0; $i < $pkcs7_cnt; $i++) {
  my $bags = $info_hash->{pkcs7_data}[$i]->{bags};

  is(scalar @$bags, 1, "One bag in pkcs7_data");

  if ($info_hash->{pkcs7_data}[$i]{bags}[0]{type} eq 'shrouded_keybag')
  {
    my $bag_attributes = @$bags[0]->{bag_attributes};
    is(keys %$bag_attributes, 3, "One bag attributes in pkcs7_data bag");
    foreach my $attribute (keys %$bag_attributes) {
      like($bag_attributes->{localKeyID}, qr/01 00 00 00/, "localKeyID bag_attributes matches") if $attribute eq "localKeyID";
      like($bag_attributes->{friendlyName}, qr/3f71af65-1687-444a-9f46-c8be194c3e8e/, "friendlyName bag_attributes matches") if $attribute eq "friendlyName";
      like($bag_attributes->{'Microsoft CSP Name'}, qr/Microsoft Enhanced Cryptographic Provider v1.0/, "Microsoft CSP Name bag_attributes matches") if $attribute eq 'Microsoft CSP Name';
    }

    my $key_attributes = @$bags[0]->{key_attributes};
    foreach my $attribute (keys %$key_attributes) {
      like($key_attributes->{'X509v3 Key Usage'}, qr/10/, "X509v3 Key Usage key_attributes matches") if $attribute eq 'X509v3 Key Usage';
    }

    like(@$bags[0]->{key}, qr/PRIVATE KEY/, "pkcs7_data found private key");
    like(@$bags[0]->{key}, qr/MOLoGVzhuryCcL7dIc5YVgfNOy71eK1Z/, "pkcs7_data key matches");
    like(@$bags[0]->{parameters}->{iteration}, qr/2000/, "pkcs7_data parameters iteration matches");
    like(@$bags[0]->{parameters}->{nid_long_name}, qr/pbeWithSHA1And3-KeyTripleDES-CBC/, "pkcs7_data parameters nid_long_name matches");
    like(@$bags[0]->{parameters}->{nid_short_name}, qr/PBE-SHA1-3DES/, "pkcs7_bag parameters nid_short_name matches");
    like(@$bags[0]->{type}, qr/shrouded_keybag/, "pkcs7_data bag type matches");
  }

  if ($info_hash->{pkcs7_data}[$i]{bags}[0]{type} eq 'certificate_bag')
  {
    my $bag_attributes = @$bags[0]->{bag_attributes};
    is(keys %$bag_attributes, 1, "One bag attributes in pkcs7_data bag");
    foreach my $attribute (keys %$bag_attributes) {
      like($bag_attributes->{localKeyID}, qr/01 00 00 00/, "localKeyID bag_attributes matches") if $attribute eq "localKeyID";
    }

    my $key_attributes = @$bags[0]->{key_attributes};
    foreach my $attribute (keys %$key_attributes) {
      like($key_attributes->{'X509v3 Key Usage'}, qr/10/, "X509v3 Key Usage key_attributes matches") if $attribute eq 'X509v3 Key Usage';
    }

    like(@$bags[0]->{cert}, qr/CERTIFICATE/, "pkcs7_data found private key");
    like(@$bags[0]->{cert}, qr/AvBgNVHREEKDAmoCQGCisGAQQBgjcUAgOgFgw/, "pkcs7_data key matches");
    like(@$bags[0]->{subject}, qr/CN = anonymous/, "pkcs7_data subject is correct");
    like(@$bags[0]->{issuer}, qr/CN = anonymous/, "pkcs7_data issuer is correct");
    like(@$bags[0]->{type}, qr/certificate_bag/, "pkcs7_data bag type matches");

  }
}
my $pkcs7_enc_cnt = scalar @{$info_hash->{pkcs7_encrypted_data}};
ok($info_hash->{pkcs7_encrypted_data}, "pkcs7_encrypted_data key exists");

ok($pkcs7_enc_cnt eq 0, "zero pkcs7_encrypted_data found");
}
done_testing;
