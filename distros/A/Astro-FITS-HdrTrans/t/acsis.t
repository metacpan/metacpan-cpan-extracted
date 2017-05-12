#!perl

use 5.006;
use strict;
use warnings;

use Test::More;
use File::Spec;

# Load NDF if we can.
my $isok = eval {
  require NDF;
  1;
};
if( !$isok ) {
  plan skip_all => "Test requires NDF module";
} else {

  # Load Astro::FITS::Header::NDF if we can.
  eval {
    require Astro::FITS::Header::NDF;
  };
  if( $@ ) {
    plan skip_all => 'Test requires Astro::FITS::Header::NDF module';
  } else {

    # Load Starlink::AST if we can. We call ndfGtwcs below.
    eval {
      require Starlink::AST;
    };
    if ($@) {
      plan skip_all => "Test requires Starlink::AST module";
    } else {
      plan tests => 26;
    }
  }
}

# Test compilation.
require_ok( 'Astro::FITS::HdrTrans' );

# Open the NDF environment.
my $status = &NDF::SAI__OK;
&NDF::ndf_begin;
&NDF::err_begin( $status );

# Read the file off disk.
my $datadir = File::Spec->catdir( 't', 'data' );
my $file = File::Spec->catfile( $datadir, "a20070425_00012_02_bl.sdf" );
my $hdr = new Astro::FITS::Header::NDF( File => $file );
my %hdr;
tie %hdr, "Astro::FITS::Header", $hdr;

# Deal with the FrameSet.
&NDF::ndf_find( &NDF::DAT__ROOT, $file, my $indf, $status );
my $wcs = &NDF::ndfGtwcs( $indf, $status );
&NDF::ndf_annul( $indf, $status );
&NDF::ndf_end( $status );

# Translate this header.
my %generic_header = Astro::FITS::HdrTrans::translate_from_FITS( \%hdr, frameset => $wcs );

isa_ok( $generic_header{'UTSTART'}, "Time::Piece", "UTSTART is Time::Piece" );
isa_ok( $generic_header{'UTEND'}, "Time::Piece", "UTEND is Time::Piece" );
is( $generic_header{'UTDATE'}, 20070425, "UTDATE year is 20070425" );
is( $generic_header{'UTSTART'}->year, 2007, "UTSTART year is 2007" );
is( $generic_header{'UTSTART'}->mon,     4, "UTSTART month is 4" );
is( $generic_header{'UTSTART'}->mday,   25, "UTSTART day is 25" );
is( $generic_header{'UTSTART'}->hour,    5, "UTSTART hour is 5" );
is( $generic_header{'UTSTART'}->minute, 16, "UTSTART minute is 16" );
is( $generic_header{'UTSTART'}->second, 18, "UTSTART second is 18" );
is( $generic_header{'UTEND'}->year, 2007, "UTEND year is 2007" );
is( $generic_header{'UTEND'}->mon,     4, "UTEND month is 4" );
is( $generic_header{'UTEND'}->mday,   25, "UTEND day is 25" );
is( $generic_header{'UTEND'}->hour,    5, "UTEND hour is 5" );
is( $generic_header{'UTEND'}->minute, 19, "UTEND minute is 19" );
is( $generic_header{'UTEND'}->second, 28, "UTEND second is 28" );
is( $generic_header{'EXPOSURE_TIME'}, 190, "EXPOSURE_TIME is 190" );
is( $generic_header{'OBSERVATION_MODE'}, "grid_pssw", "OBSERVATION_MODE is grid_pssw" );
is( $generic_header{'VELOCITY_TYPE'}, "radio", "VELOCITY_TYPE is radio" );
is( $generic_header{'OBSERVATION_ID'}, "acsis_12_20070425T051618", "OBSERVATION_ID is acsis_12_20070425T051618" );

is( sprintf( "%.3f", $generic_header{'RA_BASE'} ),  "146.944", "RA_BASE is 146.944" );
is( sprintf( "%.3f", $generic_header{'DEC_BASE'} ), "13.205", "DEC_BASE is 13.205" );
is( $generic_header{'REST_FREQUENCY'}, 345795989900, "REST_FREQUENCY is 345795989900" );
is( sprintf( "%.6f", $generic_header{'VELOCITY'} ), "-25.900000", "VELOCITY is -25.900000" );

is( $generic_header{'DR_RECIPE'}, 'REDUCE_SCIENCE_GRADIENT', "DR_RECIPE is REDUCE_SCIENCE_GRADIENT" );
is( $generic_header{'OBSERVATION_TYPE'}, 'grid', "OBSERVATION_TYPE is science" );
