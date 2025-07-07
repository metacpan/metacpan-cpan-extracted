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

#DeriveKeyPair: seed, info, ctx, deriveInput, counter, hashInput, dst, skS
#b'T\x96\xa9\xd8a\xb5\x1d\x9ey~\x83j\x13\x0f\xee\x90\x1d\xab|\x96\xee\xa7\x7fne\xbf\x1b\x9eZD\xb16'
#5496a9d861b51d9e797e836a130fee901dab7c96eea77f6e65bf1b9e5a44b136
#b'OPAQUE-DeriveAuthKeyPair'
#<sagelib.oprf.Context object at 0x7f1b8c3747c0>
#b'T\x96\xa9\xd8a\xb5\x1d\x9ey~\x83j\x13\x0f\xee\x90\x1d\xab|\x96\xee\xa7\x7fne\xbf\x1b\x9eZD\xb16\x00\x18OPAQUE-DeriveAuthKeyPair'
#1
#b'T\x96\xa9\xd8a\xb5\x1d\x9ey~\x83j\x13\x0f\xee\x90\x1d\xab|\x96\xee\xa7\x7fne\xbf\x1b\x9eZD\xb16\x00\x18OPAQUE-DeriveAuthKeyPair\x00'
#b'DeriveKeyPairVOPRF09-\x00\x00\x03'
#0xe7db44b7f7495298770af98417fdeec6c8299562325e9330a79eebf3d2a1a765


my $prefix = "VOPRF09-";
my $mode = 0x00;
my $suite_id  = 0x0003;
my $context_string = creat_context_string($prefix, $mode, $suite_id);
### context_string: unpack("H*", $context_string)
#is(unpack("H*", $context_string), '564f50524630392d000003', 'creat_context_string');

my $group_name = 'prime256v1';
my $seed = pack("H*", '5496a9d861b51d9e797e836a130fee901dab7c96eea77f6e65bf1b9e5a44b136');
my $info = 'OPAQUE-DeriveAuthKeyPair';
my $hash_name = 'SHA256';
my $expand_message_func = \&expand_message_xmd;

my $ec_key_r = derive_key_pair($group_name, $seed, $info, "DeriveKeyPair".$context_string, $hash_name, $expand_message_func);

#my $skS_bn = $skS->get0_private_key();
is($ec_key_r->{priv_bn}->to_hex(), 'E7DB44B7F7495298770AF98417FDEEC6C8299562325E9330A79EEBF3D2A1A765', 'derive_key_pair');

done_testing;
