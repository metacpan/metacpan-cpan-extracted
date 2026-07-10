#!/usr/bin/perl
use utf8;
use Test::More;
use Crypto::Utils::OpenSSL qw/bn_mod_sqrt BN_bn2hex hex2bn/;
use Data::Dumper;

my $p = hex2bn('05');
my $a = hex2bn('04');
my $s = bn_mod_sqrt( $a, $p );
ok( BN_bn2hex($s) eq '03' );

my $b = hex2bn('02');
my $z = bn_mod_sqrt( $b, $p );
ok( $z, undef );

done_testing();
