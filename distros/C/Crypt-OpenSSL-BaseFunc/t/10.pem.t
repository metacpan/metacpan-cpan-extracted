#!/usr/bin/perl
use strict;
use warnings;
#use lib '../lib';

use Test::More;
use Crypt::OpenSSL::BaseFunc;
use FindBin;
#use Smart::Comments;
use Data::Dumper;


my $group_name = 'X25519';
my $pub_pkey4 = read_pubkey_from_pem("$FindBin::RealBin/x25519_a_pub.pem");
my $pub_hex4 = read_ec_pubkey($pub_pkey4, 1);
my $pub_bin4 = pack("H*", $pub_hex4);
is($pub_bin4, pack("H*", '6752249C66966D26DDBF1A75D6ABBACDD04B9D65FFE5171FCDE492A25FFF763E'), "read_ec_pubkey_from_pem $group_name");
my $pub_pkey5 = gen_ec_pubkey($group_name, $pub_hex4);
my $pub_hex5= read_ec_pubkey($pub_pkey5, 1);
my $pub_bin5 = pack("H*", $pub_hex5);
is($pub_bin5, $pub_bin4, "gen_ec_pubkey $group_name");

my $priv_pkey4 = read_key_from_pem("$FindBin::RealBin/x25519_a_priv.pem");
my $priv_hex4 = read_key($priv_pkey4);
my $priv_bin4 = pack("H*", $priv_hex4);
is($priv_bin4, pack("H*", 'F8A6DA9856A869DB859C47C0F10021585444BA7A8E00E4FB44564F5851317B50'), "read_ec_key_from_pem $group_name");
my $priv_pkey5 = gen_ec_key($group_name,  unpack("H*", $priv_bin4));
write_key_to_pem("$FindBin::RealBin/x25519_a_priv.recover.pem", $priv_pkey5);
my $priv_hex5 = read_key($priv_pkey5);
my $priv_bin5 = pack("H*", $priv_hex5);
is($priv_bin5, $priv_bin4, "gen_ec_key $group_name");


done_testing;

1;

