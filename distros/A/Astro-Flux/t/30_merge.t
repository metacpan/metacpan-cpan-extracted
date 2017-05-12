#!perl

use strict;
use Test::More tests => 12;
use Data::Dumper;
use DateTime;

require_ok('Astro::WaveBand');
require_ok('Astro::Flux');
require_ok('Astro::FluxColor');
require_ok('Astro::Fluxes');

my $flux1 = new Astro::Flux( 1, 'mag', new Astro::WaveBand( Filter => 'J' ) );
my $flux2 = new Astro::Flux( 4, 'mag', new Astro::WaveBand( Filter => 'H' ) );
my $color1 = new Astro::FluxColor( lower => new Astro::WaveBand( Filter => 'J' ),
                                   upper => new Astro::WaveBand( Filter => 'K' ),
                                   quantity => 10 );

my $fluxes1 = new Astro::Fluxes( $flux1, $flux2, $color1 );


my $flux3 = new Astro::Flux( 10, 'mag', new Astro::WaveBand( Filter => 'J' ) );
my $flux4 = new Astro::Flux( 40, 'mag', new Astro::WaveBand( Filter => 'H' ) );
my $color2 = new Astro::FluxColor( lower => new Astro::WaveBand( Filter => 'H' ),
                                   upper => new Astro::WaveBand( Filter => 'K' ),
                                   quantity => 130 );

my $fluxes2 = new Astro::Fluxes( $flux3, $flux4, $color2 );

is( $fluxes1->color( lower => new Astro::WaveBand( Filter => 'J' ), 
                    upper => new Astro::WaveBand( Filter => 'H' ) )->quantity,
    -3, 'Retrieval of derived color');

is( $fluxes2->color( lower => new Astro::WaveBand( Filter => 'J' ), 
                    upper => new Astro::WaveBand( Filter => 'H' ) )->quantity,
    -30, 'Retrieval of derived color');
    
$fluxes1->merge( $fluxes2 );

is( $fluxes1->color( lower => new Astro::WaveBand( Filter => 'J' ), 
                    upper => new Astro::WaveBand( Filter => 'H' ) )->quantity,
    -3, 'Retrieval of derived color');

is( $fluxes1->color( lower => new Astro::WaveBand( Filter => 'H' ), 
                    upper => new Astro::WaveBand( Filter => 'K' ) )->quantity,
    130, 'Retrieval of derived color');

my $time1 = DateTime->now();
my $time2 = DateTime->now()->add( months => 1 );

my $flux5 = new Astro::Flux( 37, 'mag', new Astro::WaveBand( Filter => 'J' ) );
my $flux6 = new Astro::Flux( 38, 'mag', new Astro::WaveBand( Filter => 'H' ) );
my $color3 = new Astro::FluxColor( lower => new Astro::WaveBand( Filter => 'H' ),
                                   upper => new Astro::WaveBand( Filter => 'K' ),
                                   quantity => 13,
				   datetime =>  $time1 );
my $color4 = new Astro::FluxColor( lower => new Astro::WaveBand( Filter => 'H' ),
                                   upper => new Astro::WaveBand( Filter => 'K' ),
                                   quantity => 14.5,
				   datetime =>  $time2 );
				   
my $fluxes3 = new Astro::Fluxes( $flux5, $flux6, $color3, $color4 );
    
$fluxes1->merge( $fluxes3 );

is( $fluxes1->color( lower => new Astro::WaveBand( Filter => 'J' ), 
                    upper => new Astro::WaveBand( Filter => 'H' ) )->quantity,
    -3, 'Retrieval of derived color');

is( $fluxes1->color( lower => new Astro::WaveBand( Filter => 'H' ), 
                    upper => new Astro::WaveBand( Filter => 'K' ) )->quantity,
    130, 'Retrieval of derived color');
    
is( $fluxes1->color( lower => new Astro::WaveBand( Filter => 'H' ), 
                    upper => new Astro::WaveBand( Filter => 'K' ),
		    datetime => $time1 )->quantity,
    13, 'Retrieval of derived color');   
    
is( $fluxes1->color( lower => new Astro::WaveBand( Filter => 'H' ), 
                    upper => new Astro::WaveBand( Filter => 'K' ),
		    datetime => $time2 )->quantity,
    14.5, 'Retrieval of derived color');        
