#!/usr/bin/perl
use utf8;
use Test::More;
use Crypt::OpenSSL::BaseFunc ;

my $macdata_key = pkcs12_key_gen( '123456',  pack("H*", 'e241f01650dbeae4'), 3, 2048, 'sha256');
is( $macdata_key, pack("H*", '721259F14AAD70B58839F71566B433DA1B8AD08F650F4D02FAAA0B9B095BB51D'), 'pkcs12_key_gen');

done_testing();
