#!perl
# Test using MPC codes.

use strict;
use Test::More tests => 14;

require_ok( "Astro::Telescope" );

# Set up a new telescope with obscode 'F65';
my $tel = new Astro::Telescope( "F65" );
ok( $tel, "Created from obscode" );
is( $tel->name, "Haleakala-Faulkes Telescope North", "compare name" );
is( sprintf( "%0.6f", $tel->alt ), 3054.946596, "compare altitude" );
is( sprintf( "%0.6f", $tel->long ), 3.555976, "compare longitude" );
my( $obsx, $obsy, $obsz ) = $tel->obsgeo;
is( sprintf( "%0.6f", $obsx ), "-5466039.531076", "compare obsx" );
is( sprintf( "%0.6f", $obsy ), "-2404249.588474", "compare obsy" );
is( sprintf( "%0.6f", $obsz ), "2242157.274000", "compare obsz" );
my %parallax = $tel->parallax;
is( sprintf( "%0.9f", $parallax{Par_S}), sprintf( "%0.9f", "0.93624"), "parallax" );

# make sure we have limits
my %limits = $tel->limits;
is( $limits{type}, "AZEL", "Default limit type");
is( $limits{el}->{min}, 0.0, "Above horizon");

# Override limits
$tel->setlimits( type => "HADEC",
                 ha => { min => 0 },
                 dec => { min => 0 } );
%limits = $tel->limits;
is( $limits{type}, "HADEC", "Override limit type");

# reset obscode and check that limits have reset
$tel->obscode( "F65" );
%limits = $tel->limits;
is( $limits{type}, "AZEL", "Default limit type");
is( $limits{el}->{min}, 0.0, "Above horizon");

