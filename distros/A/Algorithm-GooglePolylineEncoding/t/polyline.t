#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#

use strict;

BEGIN {
    if (!eval q{
	use Test::More;
	1;
    }) {
	print "1..0 # skip no Test::More module\n";
	exit;
    }
}

use Getopt::Long;
my $forever;
GetOptions("forever" => \$forever)
    or die "usage?";

plan tests => 7;

use_ok 'Algorithm::GooglePolylineEncoding';

{
    my @path = ({lat => 38.5,   lon => -120.2},
		{lat => 40.7,   lon => -120.95},
		{lat => 43.252, lon => -126.453},
	       );
    roundtrip_check(\@path, '_p~iF~ps|U_ulLnnqC_mqNvxq`@');
}

is(Algorithm::GooglePolylineEncoding::encode_level(174), 'mD');

is(Algorithm::GooglePolylineEncoding::encode_number(0), '?');
is(Algorithm::GooglePolylineEncoding::encode_number(-9.99999997475243e-07), '?');

do {
    my @path;
    # Check with random numbers
    for (1..20) {
	my($lat, $lon) = (rand(180)-90, rand(360-180));
	push @path, {lat => $lat, lon => $lon};
    }
    roundtrip_check(\@path, undef)
	or do { $forever and die };
} while($forever);

sub roundtrip_check {
    my($path, $encoded) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    if (defined $encoded) {
	my $success;
	$success++ if is(Algorithm::GooglePolylineEncoding::encode_polyline(@$path), $encoded, 'encode_polyline');
	$success++ if is_deeply([Algorithm::GooglePolylineEncoding::decode_polyline($encoded)], $path, 'decode_polyline');
	return 1 if $success == 2;
    } else {
	my $encoded = Algorithm::GooglePolylineEncoding::encode_polyline(@$path);
	my @path2 = Algorithm::GooglePolylineEncoding::decode_polyline($encoded);
	my $errors = 0;
	for my $i (0 .. $#$path) {
	    my $lat_delta = abs($path2[$i]->{lat}-$path->[$i]->{lat});
	    my $lon_delta = abs($path2[$i]->{lon}-$path->[$i]->{lon});
	    if ($lat_delta > 0.00006) {
		diag "$lat_delta too large (lat index $i in path, $path->[$i]->{lat} != $path2[$i]->{lat})";
		$errors++;
	    }
	    if ($lon_delta > 0.00006) {
		diag "$lat_delta too large (lon index $i in path, $path->[$i]->{lon} != $path2[$i]->{lon})";
		$errors++;
	    }
	}
	ok($errors == 0, "Roundtrip check");
    }
}

__END__
