#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 30;
BEGIN { use_ok('Convert::zBase32') };

sub bin2dec 
{
    unpack "N", pack "B32", substr "0" x 32 . (shift||$_), -32;
}

#########################
my @split = Convert::zBase32::_split_string( pack "V", 0xffffffff );
                      # 0    1     2      3    4     5     6
is_deeply( \@split, [ 0x1f, 0x1f, 0x1f, 0x1f, 0x1f, 0x1f, 0x03 ], 
                "All ones" );

##
@split = Convert::zBase32::_split_string( pack "V", 0xaaaaaaaa );
                      # 0    1     2      3    4     5     6
is_deeply( \@split, [ 0x0a, 0x15, 0x0a, 0x15, 0x0a, 0x15, 0x02 ], 
                "Alternating 1 and 0" );

##
@split = Convert::zBase32::_split_string( pack "V", 0xF0F0F0F0 );
is_deeply( \@split, [ map bin2dec, "10000",  # 0
                                   "00111",  # 1
                                   "11100",  # 2
                                   "00001",  # 3 
                                   "01111",  # 4
                                   "11000",  # 5
                                   "00011",  # 6
                                ], 
                "Alternating nibbles" );

##
@split = Convert::zBase32::_split_string( pack "V", 0x42108421 );
is_deeply( \@split, [ (1) x 7 ], "5 bit fields" );

my $joined = Convert::zBase32::_join_string( @split );
is( unpack( "V",  $joined), 0x42108421, "Joined" );

##
@split = Convert::zBase32::_split_string( pack "V", 0x21 );
is_deeply( \@split, [ (1) x 2, (0) x 5 ], "One byte" );

$joined = Convert::zBase32::_join_string( @split );
is( unpack( "V",  $joined), 0x21, " ... round trip" );

##
@split = Convert::zBase32::_split_string( pack "V", 0x0421 );
is_deeply( \@split, [ (1) x 3, (0) x 4 ], "3 nibble" );

$joined = Convert::zBase32::_join_string( @split );
is( unpack( "V",  $joined), 0x0421, " ... round trip" );

##
@split = Convert::zBase32::_split_string( pack "V", 0x8421 );
is_deeply( \@split, [ (1) x 4, (0) x 3 ], "4 nibble" );

$joined = Convert::zBase32::_join_string( @split );
is( unpack( "V",  $joined), 0x8421, " ... round trip" );

##
@split = Convert::zBase32::_split_string( pack "V", 0x108421 );
is_deeply( \@split, [ (1) x 5, (0) x 2 ], "6 nibble" );

$joined = Convert::zBase32::_join_string( @split );
is( unpack( "V",  $joined), 0x108421, " ... round trip" );

##
@split = Convert::zBase32::_split_string( pack "V", 0x02108421 );
is_deeply( \@split, [ (1) x 6, (0) x 1 ], "7 nibble" );

$joined = Convert::zBase32::_join_string( @split );
is( unpack( "V",  $joined), 0x02108421, " ... round trip" );

##
@split = Convert::zBase32::_split_string( pack "V", 0x42108421 );
is_deeply( \@split, [ (1) x 7 ], "8 nibble" );

$joined = Convert::zBase32::_join_string( @split );
is( unpack( "V",  $joined), 0x42108421, " ... round trip" );

#############################
foreach my $string ( "this is", "Some \xff random", "hello world", 
                     "\xde\xad \xbe\xaf\xff" ) {
    my $zb = encode_zbase32( $string );
    # warn $zb;
    ok( ( $zb =~ /^[ybndrfg8ejkmcpqxot1uwisza345h769]+$/ ), "Got zbase32" );
    my $out = decode_zbase32( $zb );
    is( $out, $string, " ... round trip" );
    $out = decode_zbase32( uc $zb );
    is( $out, $string, " ... upper case safe" );
}
