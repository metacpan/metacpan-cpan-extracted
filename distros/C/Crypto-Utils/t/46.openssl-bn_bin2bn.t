#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Crypto::Utils::OpenSSL;

# 1. Test BN_bin2bn allocating a new BIGNUM from a binary string
# Let's use "DEADBEEF" in binary: \xde\xad\xbe\xef
my $bin_data = "\xde\xad\xbe\xef";
my $bn       = BN_bin2bn($bin_data);
ok( defined $bn, 'BIGNUM pointer is defined' );

my $hex_out = BN_bn2hex($bn);
is( lc($hex_out), 'deadbeef', 'Binary-to-BIGNUM hex output matches deadbeef' );

# 2. Test BN_bin2bn with custom length (only parse first 2 bytes)
my $bn_short = BN_bin2bn( $bin_data, 2 );
is( lc( BN_bn2hex($bn_short) ),
    'dead', 'Custom length parsing correctly parsed only "dead"' );

# 3. Test BN_bin2bn with an existing BIGNUM object (reusing it)
my $bin_data2 = "\x12\x34\x56\x78";
my $bn_res    = BN_bin2bn( $bin_data2, undef, $bn );
is( lc( BN_bn2hex($bn) ),
    '12345678', 'Existing BIGNUM value updated successfully' );
is( $bn_res, $bn, 'Returned BIGNUM pointer matches passed $ret pointer' );

# 4. Test handling binary strings with embedded null bytes
my $bin_data_nulls = "\x01\x00\x00\x02";
my $bn_nulls       = BN_bin2bn($bin_data_nulls);
is( lc( BN_bn2hex($bn_nulls) ),
    '01000002', 'Binary string with embedded nulls parsed correctly' );

done_testing;

1;
