#!/usr/bin/perl
use utf8;
use Test::More;
use Crypt::OpenSSL::BaseFunc ;

#aes_cmac: test vector from RFC 4493
my $key = pack("H*", '2b7e151628aed2a6abf7158809cf4f3c');

my $msg_1 =  pack("H*", '6bc1bee22e409f96e93d7e117393172a');
my $cmac_1 = aes_cmac('aes-128-cbc', $key, $msg_1 );
is($cmac_1, pack("H*", '070A16B46B4D4144F79BDD9DD04A287C'), 'aes_cmac');


my $msg_2 = pack("H*", '6bc1bee22e409f96e93d7e117393172aae2d8a571e03ac9c9eb76fac45af8e5130c81c46a35ce411');
my $cmac_2 = aes_cmac('aes-128-cbc', $key, $msg_2 );
is($cmac_2, pack("H*", 'DFA66747DE9AE63030CA32611497C827'), 'aes_cmac');

#hmac: test vector from https://en.wikipedia.org/wiki/HMAC
$key = "key";
my $data = "The quick brown fox jumps over the lazy dog";
my $hmac = pack("H*", 'f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8');
my $hmac_m = hmac('SHA-256', $key, $data);
is($hmac_m, $hmac, "hmac");

#rfc5869 hkdf
my $digest_name = "SHA256";
my $ikm = pack("H*", "0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b");
my $salt = pack("H*", "000102030405060708090a0b0c");
my $info = pack("H*", "f0f1f2f3f4f5f6f7f8f9");
my $prk_len = 32;
my $okm_len = 42;
my $prk = pack("H*", "077709362c2e32df0ddc3f0dc47bba6390b6c73bb50f9c3122ec844ad7c2b3e5");
my $okm = pack("H*", "3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865");
my $prk_d = hkdf_extract($digest_name, $ikm, $salt, $info, $prk_len);
is($prk_d, $prk, "hkdf-extract");
my $okm_d = hkdf_expand($digest_name, $prk_d, $salt, $info, $okm_len);
is($okm_d, $okm, "hkdf-expand");
my $okm_m = hkdf($digest_name, $ikm, $salt, $info, $okm_len);
is($okm_m, $okm, "hkdf");



done_testing();
