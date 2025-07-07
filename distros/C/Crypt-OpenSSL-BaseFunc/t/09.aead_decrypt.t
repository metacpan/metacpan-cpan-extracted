#!/usr/bin/perl

#use lib '../lib';

use Test::More;
use Crypt::OpenSSL::BaseFunc;
#use Smart::Comments;

my $cipher_name = 'aes-256-gcm';
my $aad = undef;

my $key = pack("H*", '9bb6f934448315173ec3cb2ba3f2c5c709c56f4ca3da3bda2f7f844ce17db26d');
my $iv = pack("H*", 'fbf0a086180eb5f3e525aa96');

my $plaintext = 'ustc328ustc328ustc328xxxxxxxxqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq';
my $ciphertext = pack("H*", 'd50bc4fe3e1096b84a2b2a57ee9d3604ddb7a46d3c82d34183e42f3f248125a31bd6b4f20a3e8f4828b3edd6848565c083125d43f55a5b43c01f868e10f33f258be3a778cab74ba0df'); 
my $tag_len = 16;
my $tag = pack("H*", '896bd8494df8fe43899b4858d6b9b00f'); 


my $enc_r = aead_encrypt($cipher_name, $plaintext, $aad, $key, $iv, $tag_len);
my $ciphertext_e = $enc_r->[0];
my $tag_e = $enc_r->[1];
is($ciphertext_e, $ciphertext, "$cipher_name encrypt");
is($tag_e, $tag, "$cipher_name encrypt tag");


my $plaintext_d = aead_decrypt($cipher_name, $ciphertext, $aad, $tag, $key, $iv);
is($plaintext_d, $plaintext, "$cipher_name plaintext");

my $ctr_cipher_name = 'aes-256-ctr';
my $iv_ctr = pack("H*", '12f7ea1db314e41aa7c0c6558cc680ad');
my $ciphertext_ctr = pack("H*", "233fd586345a37623c00fc48780ebf7a25914fa26d73541beb765144f67aa0e961a54ec96e3348f1abd7222f13c7b088ba9839c78ae9beb3352bbde9d291c48dca45481d196e44a3fa");
my $ciphertext_ctr_e = symmetric_encrypt($ctr_cipher_name, $plaintext, $key, $iv_ctr);
is($ciphertext_ctr_e, $ciphertext_ctr, "$ctr_cipher_name encrypt");
my $plaintext_ctr_d = symmetric_decrypt($ctr_cipher_name, $ciphertext_ctr_e, $key, $iv_ctr);
is($plaintext_ctr_d, $plaintext, "$ctr_cipher_name decrypt");

done_testing;

1;
