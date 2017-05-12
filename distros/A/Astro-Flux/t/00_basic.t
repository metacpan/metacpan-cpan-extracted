#!perl

use strict;
use Test::More tests => 7;

require_ok('Astro::WaveBand');
require_ok('Astro::Flux');


my $flux = new Astro::Flux( -1, 'mag',
			    new Astro::WaveBand( Filter => 'J' ));

isa_ok( $flux, 'Astro::Flux' );

is( lc($flux->type), 'mag', 'Retrieve flux type' ); 

is( $flux->quantity('mag'), -1, 'Retrieve flux');

my $wb = $flux->waveband;
isa_ok( $wb, "Astro::WaveBand");
is( $wb->filter, 'J', "compare filter");
