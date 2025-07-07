#!/usr/bin/perl
#use Digest::SHA qw/sha256/;
use List::Util qw/min/;
use strict;
use warnings;

#use lib '../lib';

use Test::More ;
use Crypt::OpenSSL::EC;
use Crypt::OpenSSL::Bignum;
use Crypt::OpenSSL::BaseFunc;
use Crypt::OpenSSL::BaseFunc;
use Crypt::Protocol::CPace ;
#use Data::Dump qw/dump/;

my $res = generator_string(
'CPaceP256_XMD:SHA-256_SSWU_NU_',
'Password',
pack("H*", "0a41696e69746961746f720a42726573706f6e646572"),
pack("H*", '34b36454cab2e7842c389f7d88ecb7df'),
64);

is(
unpack("H*", $res), 
'1e4350616365503235365f584d443a5348412d3235365f535357555f4e555f0850617373776f7264170000000000000000000000000000000000000000000000160a41696e69746961746f720a42726573706f6e6465721034b36454cab2e7842c389f7d88ecb7df', 
'generator_string'
);

done_testing;
