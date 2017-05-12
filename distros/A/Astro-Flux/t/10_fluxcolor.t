#!perl

use strict;
use Test::More tests => 6;

require_ok('Astro::WaveBand');
require_ok('Astro::FluxColor');

my $color = new Astro::FluxColor( lower => new Astro::WaveBand( Filter => 'H' ),
                                  upper => new Astro::WaveBand( Filter => 'J' ),
                                  quantity => 3 );

isa_ok( $color, 'Astro::FluxColor' );

is( $color->quantity, 3, 'Retrieve magnitude' );

my $lower = $color->lower;
isa_ok( $lower, 'Astro::WaveBand' );
is( $lower->filter, 'H', 'Compare filter' );
