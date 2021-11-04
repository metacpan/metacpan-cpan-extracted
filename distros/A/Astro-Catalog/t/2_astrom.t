#!perl

# Astro::Catalog test harness
use Test::More tests => 16;

use strict;
use File::Temp;
use Astro::Coords::Angle;
use Astro::Coords::Angle::Hour;

# Fix the precision used by Astro::Coords::Angle since we will be
# comparing values formatted as strings to this precision.
Astro::Coords::Angle->NDP(2);
Astro::Coords::Angle::Hour->NDP(3);

require_ok("Astro::Catalog");
require_ok("Astro::Catalog::Item");
require_ok("Astro::Coords");

# Create some stars with x, y, RA, Dec.
my @stararray;
my $star1 = new Astro::Catalog::Item(
        Coords => new Astro::Coords(
            ra => '18:56:39.426',
            dec => '-63:25:13.23',
            type => 'J2000',
            units => 'sexagesimal'),
        X => 44.791,
        Y => 85.643);
push @stararray, $star1;
my $star2 = new Astro::Catalog::Item(
        Coords => new Astro::Coords(
            ra => '19:11:53.909',
            dec => '-63:17:57.57',
            type => 'J2000',
            units => 'sexagesimal' ),
        X => -46.266,
        Y => 92.337 );
push @stararray, $star2;
my $star3 = new Astro::Catalog::Item(
        Coords => new Astro::Coords(
            ra => '19:01:13.606',
            dec => '-63:49:14.84',
            type => 'J2000',
            units => 'sexagesimal' ),
        X => 17.246,
        Y => 64.945 );
push @stararray, $star3;
my $star4 = new Astro::Catalog::Item(
        Coords => new Astro::Coords(
            ra => '19:08:29.088',
            dec => '-63:57:42.79',
            type => 'J2000',
            units => 'sexagesimal' ),
        X => -25.314,
        Y => 57.456 );
push @stararray, $star4;

# We need to create a catalog, then write it out and compare each
# written line with that in the DATA block.
my $catalog = new Astro::Catalog(Stars => \@stararray);
$catalog->fieldcentre(
        Coords => new Astro::Coords(
            ra => '19:04:00.0',
            dec => '-65:00:00.0',
            type => 'J2000',
            units => 'sexagesimal' ) );

isa_ok($catalog, "Astro::Catalog");

# Create a temporary file to hold the written catalogue.
my $tempfile = File::Temp->new();
ok($catalog->write_catalog(Format => 'Astrom', File => $tempfile),
    "Check catalog write" );

# Now we need to read in the catalogue into an array.
my $fh;
open $fh, $tempfile;
my @written_cat = <$fh>;
chomp @written_cat;
close $fh;

# And read the DATA block into an array.
my @data_cat = <DATA>;
chomp @data_cat;

# Compare the two arrays.
for (my $i = 0; $i < @written_cat; $i++) {
    ok($written_cat[$i] eq $data_cat[$i], "Compare written catalog line $i");
}

__DATA__
~ GENE 0.0
~ 19 04 00.000 -65 00 00.00 J2000 2000.0
18 56 39.426 -63 25 13.23 J2000 2000.0
44.791 85.643
19 11 53.909 -63 17 57.57 J2000 2000.0
-46.266 92.337
19 01 13.606 -63 49 14.84 J2000 2000.0
17.246 64.945
19 08 29.088 -63 57 42.79 J2000 2000.0
-25.314 57.456
END
