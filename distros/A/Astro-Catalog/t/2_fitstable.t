#!perl

# Test FITS binary table read

# Astro::Catalog test harness
use Test::More;
use Data::Dumper;
use File::Spec;

use strict;

eval { require Astro::FITS::CFITSIO; };
if( $@ ) {
  plan skip_all => "Tests require Astro::FITS::CFITSIO";
} else {
  plan tests => 18;
}

require_ok( "Astro::Catalog" );
require_ok( "Astro::Catalog::IO::FITSTable" );

my $file = File::Spec->catfile( "t", "data", "cat.fit" );

my $cat = new Astro::Catalog( Format => 'FITSTable',
                              File => $file );

isa_ok( $cat, "Astro::Catalog" );

is( $cat->sizeof, 672, "Size of catalog" );

my $star = $cat->popstar();
my $id = $star->id;

is( $id, 672, "Last object's ID" );

is( $star->dec, "-02 03 51.95", "Last object's Dec" );

my $fluxes = $star->fluxes;
isa_ok( $fluxes, "Astro::Fluxes" );

my @allfluxes = $fluxes->allfluxes;
foreach my $flux ( @allfluxes ) {
  isa_ok( $flux, "Astro::Flux" );
  if( lc($flux->type) eq 'isophotal_flux' ) {
    is( sprintf( "%.3f", $flux->quantity('isophotal_flux') ),
        1169.419,
        "Last object's isophotal flux" );
    is( $flux->datetime->datetime, "2004-11-27T05:49:14", "DateTime of flux measurement" );
    is( $flux->waveband->natural, "Z", "Filter of flux measurement" );
  }
}
