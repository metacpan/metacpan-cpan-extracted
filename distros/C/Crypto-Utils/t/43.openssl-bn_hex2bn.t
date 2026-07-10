#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Crypto::Utils::OpenSSL;

# 1. Test BN_hex2bn allocating a new BIGNUM object using a variable reference
my $bn           = BN_new();
my $chars_parsed = BN_hex2bn( $bn, "DEADBEEF" );
is( $chars_parsed, 8, 'Parsed 8 characters' );
ok( defined $bn, 'BIGNUM pointer is defined' );

my $hex_out = BN_bn2hex($bn);
is( lc($hex_out), 'deadbeef', 'Hex output matches original input' );

# 2. Test BN_hex2bn updating an existing BIGNUM object
my $chars_parsed2 = BN_hex2bn( $bn, "12345678" );
is( $chars_parsed2, 8, 'Parsed 8 characters on existing BIGNUM' );
my $hex_out2 = BN_bn2hex($bn);
is( lc($hex_out2), '12345678', 'Existing BIGNUM value updated successfully' );

# 3. Test negative values
my $bn_neg    = BN_new();
my $chars_neg = BN_hex2bn( $bn_neg, "-ABCDEF" );
is( $chars_neg, 7, 'Parsed 7 characters for negative hex string' );
my $hex_neg = BN_bn2hex($bn_neg);
is( lc($hex_neg), '-abcdef', 'Negative BIGNUM hex output matches' );

done_testing;

1;
