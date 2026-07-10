#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Crypto::Utils::OpenSSL;

# 1. Test BN_dec2bn allocating/parsing into a BIGNUM object
my $bn           = BN_new();
my $chars_parsed = BN_dec2bn( $bn, "3735928559" );    # DEADBEEF in decimal
is( $chars_parsed, 10, 'Parsed 10 decimal characters' );
ok( defined $bn, 'BIGNUM pointer is defined' );

my $hex_out = BN_bn2hex($bn);
is( lc($hex_out), 'deadbeef',
    'Hex output for decimal 3735928559 matches deadbeef' );

# 2. Test BN_dec2bn updating an existing BIGNUM object
my $chars_parsed2 =
  BN_dec2bn( $bn, "305419896" );    # 12345678 in hex is 305419896
is( $chars_parsed2, 9, 'Parsed 9 characters on existing BIGNUM' );
my $hex_out2 = BN_bn2hex($bn);
is( lc($hex_out2), '12345678',
    'Existing BIGNUM value updated successfully to 12345678' );

# 3. Test negative decimal values
my $bn_neg    = BN_new();
my $chars_neg = BN_dec2bn( $bn_neg, "-11259375" );    # -ABCDEF in hex
is( $chars_neg, 9, 'Parsed 9 characters for negative decimal string' );
my $hex_neg = BN_bn2hex($bn_neg);
is( lc($hex_neg), '-abcdef', 'Negative BIGNUM hex output matches -abcdef' );

done_testing;

1;
