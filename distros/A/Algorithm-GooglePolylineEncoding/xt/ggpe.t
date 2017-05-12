#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#

use strict;
use Benchmark qw(cmpthese);
use Test::More;

use Algorithm::GooglePolylineEncoding;
use Geo::Google::PolylineEncoder;

plan tests => 1;

my @path = ({lat => 38.5,   lon => -120.2},
	    {lat => 40.7,   lon => -120.95},
	    {lat => 43.252, lon => -126.453},
	   );

my $ggpe = Geo::Google::PolylineEncoder->new;
my $eline = $ggpe->encode(\@path);

is($eline->{points}, Algorithm::GooglePolylineEncoding::encode_polyline(@path));

cmpthese(-1, {'GGPE' => sub {
		  $ggpe->encode(\@path)->{points}
	      },
	      'AGPE' => sub {
		  Algorithm::GooglePolylineEncoding::encode_polyline(@path)
	      },
	     }
	);

__END__
