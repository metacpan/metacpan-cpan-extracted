#!/usr/bin/perl
use strict;
use warnings;
#use lib '../lib';

use Test::More;
use FindBin;
#use Smart::Comments;
use Data::Dumper;

use Crypt::OpenSSL::BaseFunc;

my $group_name = "prime256v1";

my $pub_pkey = read_pubkey_from_pem("$FindBin::RealBin/ecc_nist_p256_pub.pem");
my $pub_hex = read_ec_pubkey($pub_pkey, 0);
print "pub:", $pub_hex, "\n";
my $pub_bin= pack("H*", $pub_hex);
is($pub_bin, pack("H*", '04259CB35D781B478BF785DE062E1A3577348290BC05E36F3B42B496CF59BF03E965FB768014225FB520B5CBFC2F52240CD80536CAC8716412EA1AF78D4962C0AF'), "read ec pub key from pem $group_name");

my $pub_pkey2 = gen_ec_pubkey($group_name, $pub_hex);
my $pub_hex2= read_ec_pubkey($pub_pkey2, 0);
print "pub2:", $pub_hex, "\n";
is($pub_hex2, $pub_hex, "gen_ec_pubkey $group_name");
write_pubkey_to_pem("$FindBin::RealBin/ecc_nist_p256_pub.recover.pem", $pub_pkey2);

my $priv_pkey = read_key_from_pem("$FindBin::RealBin/ecc_nist_p256_priv.pem");
my $priv_hex = read_key($priv_pkey);
my $priv_bin = pack("H*", $priv_hex);
is($priv_hex, '732B18540FCB731FD3C46E6D4E19A56525346A8A30D0B7B7B2547283978584E9', "read_key_from_pem $group_name");

my $priv_pkey2 = read_key_from_der("$FindBin::RealBin/ecc_nist_p256_priv.der");
my $priv_hex2 = read_key($priv_pkey2);
my $priv_bin2 = pack("H*", $priv_hex2);
is($priv_bin2, pack("H*", '732B18540FCB731FD3C46E6D4E19A56525346A8A30D0B7B7B2547283978584E9'), "read_key_from_der $group_name");

my $priv_pkey3 = gen_ec_key($group_name,  $priv_hex);
my $priv_hex3 = read_key($priv_pkey3);
my $priv_bin3 = pack("H*", $priv_hex3);
is($priv_bin3, $priv_bin, "gen_ec_key $group_name");

my $msg = 'justfortest';
my $sig = ecdsa_sign($priv_pkey, 'sha256', $msg);
my $sig_ret = ecdsa_verify($pub_pkey, 'sha256', $msg, $sig);
is($sig_ret, 1, "ecdsa sign & ecdsa verify");

$group_name = 'prime256v1';
$priv_pkey = gen_ec_key($group_name, '732B18540FCB731FD3C46E6D4E19A56525346A8A30D0B7B7B2547283978584E9');
$priv_hex = read_key($priv_pkey);
print "priv:", $priv_hex, "\n";

$pub_pkey = export_ec_pubkey($priv_pkey);
$pub_hex = read_ec_pubkey($pub_pkey, 0);
print "pub:", $pub_hex, "\n";

$priv_pkey2 = gen_ec_key($group_name, '');
$pub_pkey2 = export_ec_pubkey($priv_pkey2);

is(ecdh($priv_pkey, $pub_pkey2), ecdh($priv_pkey2, $pub_pkey), "gen ec key");


$group_name = 'X25519';
$priv_pkey = gen_ec_key($group_name, 'C045A847EE3472F65B218AF2642EB563B8E9D8E7E9E3B1B118775347FBE54D66');
$priv_hex = read_key($priv_pkey);
print "priv:", $priv_hex, "\n";

$pub_pkey = export_ec_pubkey($priv_pkey);
$pub_hex = read_ec_pubkey($pub_pkey, 0);
print "pub:", $pub_hex, "\n";

$priv_pkey2 = gen_ec_key($group_name, '');
$pub_pkey2 = export_ec_pubkey($priv_pkey2);

is(ecdh($priv_pkey, $pub_pkey2), ecdh($priv_pkey2, $pub_pkey), "gen ec key");



done_testing();

1;

