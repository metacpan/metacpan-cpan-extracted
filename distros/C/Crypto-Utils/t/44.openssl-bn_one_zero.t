#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Crypto::Utils::OpenSSL
  qw(BN_value_one BN_one BN_zero BN_bn2hex BN_hex2bn BN_new BN_CTX_new BN_add BN_sub BN_mod bn_mod BN_rand_range);

# 1. Test BN_value_one
my $one = BN_value_one();
ok( defined $one, 'BN_value_one returns defined pointer' );
is( lc( BN_bn2hex($one) ), '01', 'BN_value_one is indeed 1' );

# 2. Test BN_one
my $bn = BN_new();
ok( defined $bn, 'BN_new returns defined object' );
BN_one($bn);
is( lc( BN_bn2hex($bn) ), '01', 'BN_one sets BIGNUM to 1' );

# 3. Test BN_zero
BN_zero($bn);
is( lc( BN_bn2hex($bn) ), '0', 'BN_zero sets BIGNUM to 0' );

# 4. Test BN_add and BN_sub
my $bn_a = BN_new();
my $bn_b = BN_new();
my $bn_r = BN_new();

BN_one($bn_a);
BN_one($bn_b);
BN_add( $bn_r, $bn_a, $bn_b );
is( lc( BN_bn2hex($bn_r) ), '02', 'BN_add computes 1 + 1 = 2' );

BN_sub( $bn_r, $bn_r, $bn_a );
is( lc( BN_bn2hex($bn_r) ), '01', 'BN_sub computes 2 - 1 = 1' );

# 5. Test BN_rand_range
my $rnd   = BN_new();
my $range = BN_new();
BN_hex2bn( $range, "0a" );
my $status = BN_rand_range( $rnd, $range );
is( $status, 1, 'BN_rand_range returns 1 on success' );
my $rnd_hex = BN_bn2hex($rnd);
my $rnd_val = hex($rnd_hex);
ok( $rnd_val >= 0 && $rnd_val < 10,
    "BN_rand_range generated value ($rnd_val) is within [0, 9]" );

# 6. Test BN_CTX_new
my $ctx = BN_CTX_new();
ok( defined $ctx, 'BN_CTX_new returns defined pointer' );

# 7. Test BN_mod
my $r = BN_new();
my $m = BN_new();
my $d = BN_new();
BN_hex2bn( $m, "15" );    # 21
BN_hex2bn( $d, "05" );    # 5
my $mod_status = BN_mod( $r, $m, $d, $ctx );
is( $mod_status,          1, 'BN_mod returns 1 on success' );
is( hex( BN_bn2hex($r) ), 1, '21 mod 5 is 1' );

# 8. Test bn_mod alias
my $r2          = BN_new();
my $mod_status2 = bn_mod( $r2, $m, $d, $ctx );
is( $mod_status2,          1, 'bn_mod returns 1 on success' );
is( hex( BN_bn2hex($r2) ), 1, 'bn_mod alias: 21 mod 5 is 1' );

done_testing;

1;
