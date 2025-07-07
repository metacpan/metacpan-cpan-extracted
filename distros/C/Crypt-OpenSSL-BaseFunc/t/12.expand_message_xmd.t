#!/usr/bin/perl
use utf8;
use Test::More;
#use Data::Dump qw/dump/;
use bignum;

use Crypt::OpenSSL::BaseFunc ;

my $res;
$res = expand_message_xmd('abc', 'QUUX-V01-CS02-with-expander', 0x20, 'SHA256');
is(unpack("H*", $res), "1c38f7c211ef233367b2420d04798fa4698080a8901021a795a1151775fe4da7", "expand_message_xmd(SHA-256)");
$res = expand_message_xmd('q128_qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq', 'QUUX-V01-CS02-with-expander', 32, 'SHA256');
is(unpack("H*", $res), "72d5aa5ec810370d1f0013c0df2f1d65699494ee2a39f72e1716b1b964e1c642", "expand_message_xmd(SHA-256)");

done_testing();
