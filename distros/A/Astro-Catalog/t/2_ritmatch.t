#!perl

# Test RITMatch format read and write

use Test::More tests => 15;

use strict;
use File::Spec;
use File::Temp;

require_ok( "Astro::Catalog" );
require_ok( "Astro::WaveBand" );

my $cat = new Astro::Catalog( Format => 'RITMatch', Data => \*DATA );
isa_ok( $cat, "Astro::Catalog" );

# Test the third object.
my @stars = $cat->stars;
my $star = $stars[2];

isa_ok( $star, "Astro::Catalog::Item" );
is( $star->id, "3", "RITMatch Star ID" );
is( $star->x, "10", "RITMatch Star X" );
is( $star->y, "23", "RITMatch Star Y" );
isa_ok( $star->fluxes, "Astro::Fluxes" );
my $fluxes = $star->fluxes;
my $flux = $fluxes->flux( waveband => new Astro::WaveBand( Filter => 'J' ) );
isa_ok( $flux, "Astro::Flux" );
is( $flux->quantity('mag'), "-9.3", "RIT Star magnitude" );

# Write out a file and read it back in.
my $fh = new File::Temp;
my $tempfile = $fh->filename;
ok( $cat->write_catalog( Format => 'RITMatch', File => $tempfile ),
    "Writing catalogue to disk" );

my $newcat = new Astro::Catalog( Format => 'RITMatch', File => $tempfile );

isa_ok( $newcat, "Astro::Catalog" );

my @newstars = $newcat->stars;
my $newstar = $newstars[2];
is( $newstar->id, $star->id, "RITMatch written catalogue ID" );
is( $newstar->x, $star->x, "RITMatch written catalogue X" );
is( $newstar->y, $star->y, "RITMatch written catalogue Y" );

__DATA__
1 20 20 -5.6
2 40 35 -6.5
3 10 23 -9.3
4 49 28 -2.3
5 32 21 -0.9
