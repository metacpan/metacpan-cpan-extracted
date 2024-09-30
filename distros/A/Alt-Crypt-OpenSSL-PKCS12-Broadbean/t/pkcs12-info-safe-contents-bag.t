use strict;
use warnings;
use Test::More;
use Digest::SHA qw/sha256_hex/;
use Crypt::OpenSSL::Guess qw/openssl_version/;

my ($major, $minor, $patch) = openssl_version();
BEGIN { use_ok('Crypt::OpenSSL::PKCS12') };
my $openssl_output =<< 'OPENSSL_END';
MAC: sha1, Iteration 2048
MAC length: 20, salt length: 20
PKCS7 Data
Safe Contents bag
Bag Attributes: <No Attributes>
Certificate bag
Bag Attributes
    localKeyID: 01 
subject=CN = RSAKeyTransferCapi1
issuer=CN = RSAKeyTransferCapi1
-----BEGIN CERTIFICATE-----
MIICDDCCAXmgAwIBAgIQXS//+GO6vJtNPICrF4pMyjAJBgUrDgMCHQUAMB4xHDAa
BgNVBAMTE1JTQUtleVRyYW5zZmVyQ2FwaTEwHhcNMTUwNDE1MDcwMDAwWhcNMjUw
NDE1MDcwMDAwWjAeMRwwGgYDVQQDExNSU0FLZXlUcmFuc2ZlckNhcGkxMIGfMA0G
CSqGSIb3DQEBAQUAA4GNADCBiQKBgQCqJycAWGwMxBsFxlx9hG9aK8J7A+MBw32b
/211tutmcbqVlsXGO6Kxr1wxjZyjnnQA0QwjiscmMFeSEbhlcNGh1E7Iaqj2ydK0
4oPqNTWSPzmKMSoj6urNjTT6rKllzZELN9pAk+92wTszfBr6t9HQfjF7QaM2uqQR
Epn5lCRAjQIDAQABo1MwUTBPBgNVHQEESDBGgBAVQy2xFrNdB+S6ie2yRp16oSAw
HjEcMBoGA1UEAxMTUlNBS2V5VHJhbnNmZXJDYXBpMYIQXS//+GO6vJtNPICrF4pM
yjAJBgUrDgMCHQUAA4GBAIHlU12Ozu8mWsvIL2xfi8nYQxkmXzzPIzafpTPI3Bk4
lSxZMWYtns2LHnuBdJ5IRoFn4vzj0Bn6cNVGRpdbbcKjunLVpSdMGGbabXpd9Hk4
4DSgddEZV9ZTtceOUpHkQBBFV29tTtqBvvPDaa9WEh5JoIPI0a2wnykYIumaQpZG
-----END CERTIFICATE-----
PKCS7 Data
Certificate bag
Bag Attributes
    localKeyID: 02 
subject=CN = RSASha256KeyTransfer1
issuer=CN = RSASha256KeyTransfer1
-----BEGIN CERTIFICATE-----
MIIB1DCCAT2gAwIBAgIQcsbHc0kWRoxNYIJT2gF2djANBgkqhkiG9w0BAQsFADAg
MR4wHAYDVQQDExVSU0FTaGEyNTZLZXlUcmFuc2ZlcjEwHhcNMTYwNDE4MTA1OTQ2
WhcNMTcwNDE4MTY1OTQ2WjAgMR4wHAYDVQQDExVSU0FTaGEyNTZLZXlUcmFuc2Zl
cjEwgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBAMrQRt46f23Hj8Wk4B0ffZDb
WW9YYzTVcIrsuOUta7kSwLXsljOoK0q6xMKGDHZvL98ckFxKcqVK39BBravl8q/R
4q2IYVlw6BjcPU0Au2xM6UxetOPv7dgNFMPSlepHGuQwy7ILBxWC8TljafvpDBSq
X4W447FAEdgfvUHssUldAgMBAAGjDzANMAsGA1UdDwQEAwIFIDANBgkqhkiG9w0B
AQsFAAOBgQC67Spa4tEe5CCcBpTHkOcuPorTELJQayd9fAAbCfZg1I26hGrFu++X
ZTYTrfU9diT8myszfyXLM3QieQDP774v2skrT3ac8r8777SF8oKoW/sJRUt5fOUo
beVgwhn7Ddb84EQq2/7092fprIHPPpcBuvge/HOg7YhXat/xJBO4Jw==
-----END CERTIFICATE-----
OPENSSL_END
if ($major eq '1.0') {
  $openssl_output =~ s/MAC: sha1, Iteration 2048/MAC Iteration 2048/g;
  $openssl_output =~ s/MAC length: .*/MAC verified OK/;
}

SKIP: {

    skip ("Pre OpenSSL 1.1.0h release cannot parse this p12 file", 22) if ($major le '1.0' or ($major le '1.1' and $patch lt 'h'));
 
my $pass   = "hi";
my $pkcs12 = Crypt::OpenSSL::PKCS12->new_from_file('certs/safe_contents.p12');

my $info = $pkcs12->info($pass);

ok(sha256_hex($info) eq sha256_hex($openssl_output), "Output matches OpenSSL");

my $info_hash = $pkcs12->info_as_hash($pass);

if ($major gt '1.0') {
  like($info_hash->{mac}{digest}, qr/sha1/, "MAC Digest is sha1");
  like($info_hash->{mac}{length}, qr/20/, "MAC length is 20");
  like($info_hash->{mac}{salt_length}, qr/20/, "MAC salt_length is 208");
}

like($info_hash->{mac}{iteration}, qr/2048/, "MAC Iteration is 2048");
my $pkcs7_cnt = scalar @{$info_hash->{pkcs7_data}};
ok($info_hash->{pkcs7_data}, "pkcs7_data key exists");

  my $bags = $info_hash->{pkcs7_data}[0]->{safe_contents_bag}[0]->{bags};

  is(scalar @$bags, 1, "One safe_contents_bag in pkcs7_data");

  my $bag_attributes = @$bags[0]->{bag_attributes};

  is(keys %$bag_attributes, 1, "One bag attributes in bag");
  foreach my $attribute (keys %$bag_attributes) {
        like($bag_attributes->{localKeyID}, qr/01/, "localKeyID matches") if $attribute eq "localKeyID";
  }

  like(@$bags[0]->{cert}, qr/CERTIFICATE/, "pkcs7_data found certificate 0");
  like(@$bags[0]->{cert}, qr/4GNADCBiQKBgQCqJycAWGwMxBsFx/, "pkcs7_data key matches");
  like(@$bags[0]->{type}, qr/certificate_bag/, "pkcs7_data bag type matches");

  like(@$bags[0]->{issuer}, qr/RSAKeyTransferCapi1/, "pkcs7_data issuer matches");
  like(@$bags[0]->{subject}, qr/RSAKeyTransferCapi1/, "pkcs7_data subject matches");

  $bags = $info_hash->{pkcs7_data}[1]->{bags};
  like(@$bags[0]->{cert}, qr/CERTIFICATE/, "pkcs7_data found certificate 1");
  like(@$bags[0]->{cert}, qr/wLXsljOoK0q6xMKGDHZvL98ck/, "pkcs7_data key matches");
  like(@$bags[0]->{type}, qr/certificate_bag/, "pkcs7_data bag type matches");

  like(@$bags[0]->{issuer}, qr/RSASha256KeyTransfer1/, "pkcs7_data issuer matches");
  like(@$bags[0]->{subject}, qr/RSASha256KeyTransfer1/, "pkcs7_data subject matches");

  $bag_attributes = @$bags[0]->{bag_attributes};
  is(keys %$bag_attributes, 1, "One bag attributes in bag");

  foreach my $attribute (keys %$bag_attributes) {
        like($bag_attributes->{localKeyID}, qr/02/, "localKeyID matches") if $attribute eq "localKeyID";
  }
}
done_testing;
