#!/usr/bin/perl
use utf8;
use strict;
use Test::More;
use Crypt::OpenSSL::BaseFunc ;
use FindBin;

my $a_priv = read_key_from_pem("$FindBin::Bin/x25519_a_priv.pem");
my $b_pub =  read_key_from_pem("$FindBin::Bin/x25519_b_pub.pem");
my $z = ecdh($a_priv, $b_pub);

my $b_priv = read_key_from_pem("$FindBin::Bin/x25519_b_priv.pem");
my $a_pub =  read_key_from_pem("$FindBin::Bin/x25519_a_pub.pem");
my $z2 = ecdh($b_priv, $a_pub);

is($z, $z2, 'ecdh');

done_testing();
