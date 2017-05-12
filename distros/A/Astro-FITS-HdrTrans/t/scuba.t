#!perl

use 5.006;
use strict;
use warnings;

use Test::More;
use File::Spec;

# Load Astro::FITS::Header if we can.
eval {
  require Astro::FITS::Header;
};
if( $@ ) {
  plan skip_all => 'Test requires Astro::FITS::Header module';
} else {
  plan tests => 21;
}

# Test compilation.
require_ok( 'Astro::FITS::HdrTrans' );

# Read the header off disk.
my $datadir = File::Spec->catdir( 't', 'data' );
my $fits = readfits( File::Spec->catfile( $datadir, 'scuba.hdr' ) );
die "Error reading FITS headers from scuba.hdr"
  unless defined $fits;
my %hdr;
tie %hdr, "Astro::FITS::Header", $fits;

# Translate this header.
my %generic_header = Astro::FITS::HdrTrans::translate_from_FITS( \%hdr );

is( $generic_header{'UTDATE'}, 20040312, "UTDATE year is 20040312" );
is( $generic_header{'UTSTART'}->year, 2004, "UTSTART year is 2004" );
is( $generic_header{'UTSTART'}->mon,     3, "UTSTART month is 3" );
is( $generic_header{'UTSTART'}->mday,   12, "UTSTART day is 12" );
is( $generic_header{'UTSTART'}->hour,   23, "UTSTART hour is 23" );
is( $generic_header{'UTSTART'}->minute, 50, "UTSTART minute is 50" );
is( $generic_header{'UTSTART'}->second, 25, "UTSTART second is 25" );
is( $generic_header{'UTEND'}->year, 2004, "UTEND year is 2004" );
is( $generic_header{'UTEND'}->mon,     3, "UTEND month is 3" );
is( $generic_header{'UTEND'}->mday,   12, "UTEND day is 12" );
is( $generic_header{'UTEND'}->hour,   23, "UTEND hour is 23" );
is( $generic_header{'UTEND'}->minute, 54, "UTEND minute is 54" );
is( $generic_header{'UTEND'}->second, 51, "UTEND second is 51" );
is( $generic_header{'CHOP_COORDINATE_SYSTEM'}, "Alt/Az", "CHOP_COORDINATE_SYSTEM is Alt/Az" );
is( $generic_header{'COORDINATE_TYPE'}, "planet", "COORDINATE_TYPE is planet" );
is( $generic_header{'EQUINOX'}, "planet", "EQUINOX is planet" );
is( $generic_header{'OBSERVATION_MODE'}, "imaging", "OBSERVATION_MODE is imaging" );
is( $generic_header{'OBSERVATION_TYPE'}, "ALIGN", "OBSERVATION_TYPE is ALIGN" );
is( $generic_header{'POLARIMETRY'}, 0, "POLARIMETRY is 0" );
is( $generic_header{'OBSERVATION_ID'}, "scuba_16_20040312T235025", "OBSERVATION_ID is scuba_16_20040312T235025" );

sub readfits {
  my $file = shift;
  open my $fh, "<", $file or die "Error opening header file $file: $!";
  my @cards = <$fh>;
  close $fh;
  return new Astro::FITS::Header( Cards => \@cards );
}
