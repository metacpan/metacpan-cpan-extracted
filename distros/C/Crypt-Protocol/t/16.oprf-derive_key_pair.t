#!/usr/bin/perl
use strict;
use warnings;

#use lib '../lib';

#use Digest::SHA qw/sha256/;
#use List::Util qw/min/;
use Test::More ;
use Crypt::OpenSSL::EC;
use Crypt::OpenSSL::Bignum;
use Crypt::OpenSSL::BaseFunc;
use Crypt::OpenSSL::BaseFunc;
use Crypt::Protocol::OPRF ;
#use Data::Dump qw/dump/;
#use Smart::Comments;


my $prefix = "VOPRF09-";
my $mode = 0x00;
my $suite_id  = 0x0003;

my $context_string = creat_context_string($prefix, $mode, $suite_id);
### context_string: unpack("H*", $context_string)
is(unpack("H*", $context_string), '564f50524630392d000003', 'creat_context_string');

my $group_name = 'prime256v1';
my $seed = pack("H*", 'a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3');
my $info = pack("H*", '74657374206b6579');
my $hash_name = 'SHA256';
my $expand_message_func = \&expand_message_xmd;

my $ec_key_r = derive_key_pair($group_name, $seed, $info, "DeriveKeyPair".$context_string, $hash_name, $expand_message_func);

#my $skS_bn = $skS->get0_private_key();
is($ec_key_r->{priv_bn}->to_hex(), '88A91851D93AB3E4F2636BABC60D6CE9D1AEE2B86DECE13FA8590D955A08D987', 'derive_key_pair');

done_testing;
