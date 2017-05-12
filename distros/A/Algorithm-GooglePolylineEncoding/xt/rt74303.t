#!/usr/bin/perl

# This script is based on a script provided in RT 74303.
# Check for good roundtrip results.

# run 
# $ perl this_file somefile.kml
# it will show how 
#   Algorithm::GooglePolylineEncoding::encode_polyline();
# consistently gives worse roundtrip results than the other algorithm
# here. Repent Now! :-)
# Try it on small and large region KML files.

use strict;
use warnings FATAL => 'all';
use Test::More 'no_plan';

use FindBin;
use blib "$FindBin::RealBin/..";
use Algorithm::GooglePolylineEncoding;

my $kml = shift || "$FindBin::RealBin/friedrichshagen.kml";

my @v;
my @polyline;
open my $fh, $kml or die "Can't open $kml: $!";
while (<$fh>) {
    if (/([0-9.]+),([0-9.]+)/) {
        push @v, ( [ $2, $1 ] );
        push @polyline, { lat => $2, lon => $1 };
    }
}

my $oo = Google_Encode( [@v] );
my $encoded_polyline =
  Algorithm::GooglePolylineEncoding::encode_polyline(@polyline);

is $oo, $encoded_polyline;

exit 0;

my $c;
for my $p (    $oo, $encoded_polyline  )
{
    print "******* Roundtrip ",++$c," **************\n";
    my @j = Algorithm::GooglePolylineEncoding::decode_polyline($p);
    my @t;
    for ( 0 .. $#j ) {
        for my $w (qw/lon lat/) {
            my $m = sprintf "%03.5f", $polyline[$_]{$w};
            $m .= "00000";
            $m =~ /\.(\d{5})/;
            $t[$_]{$w} = $1;
        }
        for my $w (qw/lon lat/) {
            my $m = sprintf "%03.5f", $j[$_]{$w};
            $m .= "00000";
            $m =~ /\.(\d{5})/;
            $j[$_]{$w} = $1;
        }

        for my $w (qw/lon lat/) {
            my $z = $t[$_]{$w} - $j[$_]{$w};
	    next unless $z;
            print "***$w $z:\t", $t[$_]{$w}, " ", $j[$_]{$w}, "\n";
    }
}}

sub Google_Encode {
    my $pointsRef     = shift;
    my @points        = @{$pointsRef};
    my $encodedPoints = '';
    $encodedPoints = &createEncodings( \@points );
    return ($encodedPoints);
}

# ############## Numeric subroutines below #############################
# Documentation from Google http://www.google.com/apis/maps/documentation/polylinealgorithm.html
#
#   1. Take the initial signed value:
#	  -179.9832104
#   2. Take the decimal value and multiply it by 1e5, flooring the result:
#	  -17998321
### Jidanni: they now say 'round' the result!
sub createEncodings {
    my $pointsRef      = shift;
    my @points         = @{$pointsRef};
    my $encoded_points = '';
    my $pointRef       = '';
    my @point          = ();
    my $plat           = 0;
    my $plng           = 0;
    my $lat            = 0;
    my $lng            = 0;
    my $late5          = 0;
    my $lnge5          = 0;
    my $dlat           = 0;
    my $dlng           = 0;
    my $i              = 0;

    for ( $i = 0 ; $i < scalar(@points) ; $i++ ) {

        $pointRef = $points[$i];
        @point    = @{$pointRef};
        $lat      = $point[0];
        $lng      = $point[1];
##use POSIX;
##        $late5    = floor( $lat * 1e5 );
        $late5 = sprintf "%.0f", $lat * 1e5;
##        $lnge5    = floor( $lng * 1e5 );
        $lnge5 = sprintf "%.0f", $lng * 1e5;
        $dlat  = $late5 - $plat;
        $dlng  = $lnge5 - $plng;
        $plat  = $late5;
        $plng  = $lnge5;
#warn "$dlat $dlng";
        $encoded_points .=
          &encodeSignedNumber($dlat) . &encodeSignedNumber($dlng);
    }
    return $encoded_points;
}

#   3. Convert the decimal value to binary. Note that a negative value must be inverted
#      and provide padded values toward the byte boundary:
#	  00000001 00010010 10100001 11110001
#	  11111110 11101101 10100001 00001110
#	  11111110 11101101 01011110 00001111
#   4. Shift the binary value:
#	  11111110 11101101 01011110 00001111 0
#   5. If the original decimal value is negative, invert this encoding:
#	  00000001 00010010 10100001 11110000 1
#   6. Break the binary value out into 5-bit chunks (starting from the right hand side):
#	  00001 00010 01010 10000 11111 00001
#   7. Place the 5-bit chunks into reverse order:
#	  00001 11111 10000 01010 00010 00001
#   8. OR each value with 0x20 if another bit chunk follows:
#	  100001 111111 110000 101010 100010 000001
#   9. Convert each value to decimal:
#	  33 63 48 42 34 1
#  10. Add 63 to each value:
#	  96 126 111 105 97 64
#  11. Convert each value to its ASCII equivalent:
#	  `~oia@

sub encodeSignedNumber {
    use integer;
    my $num     = shift;
    my $sgn_num = $num << 1;

    if ( $num < 0 ) {
        $sgn_num = ~($sgn_num);
    }
    return &encodeNumber($sgn_num);
}

sub encodeNumber {
    use integer;
    my $encodeString = '';
    my $num          = shift;
    my $nextValue    = 0;
    my $finalValue   = 0;

    while ( $num >= 0x20 ) {
        $nextValue = ( 0x20 | ( $num & 0x1f ) ) + 63;
        $encodeString .= chr($nextValue);
        $num >>= 5;
    }
    $finalValue = $num + 63;
    $encodeString .= chr($finalValue);
    return $encodeString;
}
