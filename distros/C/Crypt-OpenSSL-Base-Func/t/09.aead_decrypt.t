#!/usr/bin/perl

#use lib '../lib';

use Test::More;
use Crypt::OpenSSL::Base::Func;
#use Smart::Comments;

my $cipher_name = 'aes-256-gcm';

my $key = pack("H*", '9bb6f934448315173ec3cb2ba3f2c5c709c56f4ca3da3bda2f7f844ce17db26d');
my $iv = pack("H*", 'fbf0a086180eb5f3e525aa96');

my $plaintext = 'ustc328ustc328ustc328xxxxxxxxqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq';
my $aad = undef;

my $tag_len = 16;

my $ciphertext2 = pack("H*", 'd50bc4fe3e1096b84a2b2a57ee9d3604ddb7a46d3c82d34183e42f3f248125a31bd6b4f20a3e8f4828b3edd6848565c083125d43f55a5b43c01f868e10f33f258be3a778cab74ba0df'); 
my $tag2 = pack("H*", '896bd8494df8fe43899b4858d6b9b00f'); 
my $recover = aead_decrypt($cipher_name, $ciphertext2, $aad, $tag2, $key, $iv);
is($recover, $plaintext, 'aes-256-gcm plaintext');

done_testing;

1;
