use strict;
use warnings;
use utf8;

use Test::More;
use Test::Warn;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

use version;

plan tests => 35;

require Class::Measure::Scientific::FX_992vb;
my $m = Class::Measure::Scientific::FX_992vb->volume( 1, 'm3' );
is( $m->m3(),         1,                q{1m3 via volume} );
is( $m->bbl(),        6.2898107707486,  q{1m3 in barrel via volume} );
is( $m->dry_barrel(), 8.64848980964333, q{1m3 in dry barrel via volume} );
is( $m->bushel_uk(),  27.4960998260312, q{1m3 in bushel uk via volume} );
is( $m->bu(),         28.3775932639421, q{1m3 in bushel via volume} );
is( $m->cu(),         4226.75283773037, q{1m3 in cu via volume} );
is( $m->pt_dry(),     1816.16596853606, q{1m3 in dry pint via volume} );
is( $m->fbm(),        423.776000657863, q{1m3 in board foot via volume} );
is( $m->floz_uk(),    35195.0077685717, q{1m3 in fluid ounce UK via volume} );
is( $m->floz_us(),    33814.022701843,  q{1m3 in fluid ounce US via volume} );
is( $m->gal_uk(),     219.968798553573, q{1m3 in gallon UK via volume} );
is( $m->gal_us(),     264.172052358148, q{1m3 in gallon US via volume} );
is( $m->pk(),         113.510373033607, q{1m3 in peck via volume} );
is( $m->pt_uk(),      1759.75038842859, q{1m3 in pint via volume} );
is( $m->pt_us(),      2113.37641886519, q{1m3 in liquid pint via volume} );
is( $m->tbsp(),       67628.0454034573, q{1m3 in tablespoon via volume} );
is( $m->tsp(),        202884.136211058, q{1m3 in teaspoon via volume} );

# https://en.wikipedia.org/wiki/Barrel_(unit)
$m = Class::Measure::Scientific::FX_992vb->volume( .1, 'm3' );
is( sprintf( q{%.0f}, $m->gal_uk() ), 22, q{100L in UK gallon} );
is( sprintf( q{%.0f}, $m->gal_us() ), 26, q{100L in US gallon} );
$m = Class::Measure::Scientific::FX_992vb->volume( .2, 'm3' );
is( sprintf( q{%.0f}, $m->gal_uk() ), 44, q{200L in UK gallon} );
is( sprintf( q{%.0f}, $m->gal_us() ), 53, q{200L in US gallon} );
$m = Class::Measure::Scientific::FX_992vb->volume( 1, 'dry_barrel' );
is( sprintf( q{%.4f}, $m->m3() ), 0.1156, q{1 dry barrel in m3} );
is( sprintf( q{%.2f}, $m->bu() ), 3.28,   q{1 dry barrel in US bushels} );
$m = Class::Measure::Scientific::FX_992vb->volume( 0.0955, 'm3' );
is( sprintf( q{%.2f}, $m->bu() ), 2.71, q{95.5L in US bushels} );
$m = Class::Measure::Scientific::FX_992vb->volume( .142, 'm3' );
is( sprintf( q{%d}, $m->gal_us() ), 37, q{0.142m3 in US gallon} );
$m = Class::Measure::Scientific::FX_992vb->volume( 36, 'gal_uk' );
is( sprintf( q{%.0f}, $m->gal_us() ), 43,    q{36 UK gallon in US gallon} );
is( sprintf( q{%.3f}, $m->m3() ),     0.164, q{36 UK gallon in m3} );
$m = Class::Measure::Scientific::FX_992vb->volume( 31.5, 'gal_us' );
is( sprintf( q{%.0f}, $m->gal_uk() ), 26,    q{31.5 US gallon in UK gallon} );
is( sprintf( q{%.3f}, $m->m3() ),     0.119, q{31.5 US gallon in m3} );
$m = Class::Measure::Scientific::FX_992vb->volume( 31, 'gal_us' );
is( sprintf( q{%.0f}, $m->gal_uk() ), 26,    q{31 US gallon in UK gallon} );
is( sprintf( q{%.3f}, $m->m3() ),     0.117, q{31 US gallon in m3} );
$m = Class::Measure::Scientific::FX_992vb->volume( 1, 'bbl' );
is( sprintf( q{%.0f}, $m->gal_us() ), 42,    q{1 barrel in US gallon} );
is( sprintf( q{%.3f}, $m->m3() ),     0.159, q{1 barrel in m3} );
is( sprintf( q{%.0f}, $m->gal_uk() ), 35,    q{1 barrel in UK gallon} );

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
