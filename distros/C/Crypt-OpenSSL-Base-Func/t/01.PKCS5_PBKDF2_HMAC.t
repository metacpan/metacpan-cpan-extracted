#!/usr/bin/perl
use utf8;
use Test::More;
use Crypt::OpenSSL::Base::Func qw/PKCS5_PBKDF2_HMAC/;

my $pbkdf2_key_bin = PKCS5_PBKDF2_HMAC('123456', pack("H*", 'b698314b0d68bcbd'), 2048, 'sha256', 32);
print "pbkdf2: ", unpack("H*", $pbkdf2_key_bin), "\n";
is(unpack("H*", $pbkdf2_key_bin), 'f68b5386de3a8d6335846950544d29a55ad3328dea17685304d7822848aec534', 'PKCS5_PBKDF2_HMAC');

done_testing();
