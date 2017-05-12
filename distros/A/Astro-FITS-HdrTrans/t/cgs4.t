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
  plan tests => 23;
}

# Test compilation.
require_ok( 'Astro::FITS::HdrTrans' );

# Read the header off disk.
my $datadir = File::Spec->catdir( 't', 'data' );
my $fits = readfits( File::Spec->catfile( $datadir, 'cgs4.hdr' ) );
die "Error reading FITS headers from cgs4.hdr"
  unless defined $fits;
my %hdr;
tie %hdr, "Astro::FITS::Header", $fits;

# Translate this header.
my %generic_header = Astro::FITS::HdrTrans::translate_from_FITS( \%hdr );

isa_ok( $generic_header{'UTSTART'}, "Time::Piece", "UTSTART is Time::Piece" );
isa_ok( $generic_header{'UTEND'}, "Time::Piece", "UTEND is Time::Piece" );
is( $generic_header{'UTDATE'}, 20050126, "UTDATE year is 20050126" );
is( $generic_header{'UTSTART'}->year, 2005, "UTSTART year is 2005" );
is( $generic_header{'UTSTART'}->mon,     1, "UTSTART month is 1" );
is( $generic_header{'UTSTART'}->mday,   26, "UTSTART day is 26" );
is( $generic_header{'UTSTART'}->hour,    7, "UTSTART hour is 7" );
is( $generic_header{'UTSTART'}->minute,  6, "UTSTART minute is 6" );
is( $generic_header{'UTSTART'}->second, 57, "UTSTART second is 57" );
is( $generic_header{'UTEND'}->year, 2005, "UTEND year is 2005" );
is( $generic_header{'UTEND'}->mon,     1, "UTEND month is 1" );
is( $generic_header{'UTEND'}->mday,   26, "UTEND day is 26" );
is( $generic_header{'UTEND'}->hour,    7, "UTEND hour is 7" );
is( $generic_header{'UTEND'}->minute, 11, "UTEND minute is 11" );
is( $generic_header{'UTEND'}->second,  9, "UTEND second is 9" );
is( $generic_header{'EXPOSURE_TIME'}, "120.000", "EXPOSURE_TIME is 120" );
is( $generic_header{'OBSERVATION_ID'}, "cgs4_64_20050126T070657", "OBSERVATION_ID is cgs4_64_20050126T070657" );
is( $generic_header{'POLARIMETRY'}, 0, "POLARIMETRY is 0" );
is( $generic_header{'DEC_TELESCOPE_OFFSET'}, -5.736, "DEC_TELESCOPE_OFFSET is -5.736" );
is( $generic_header{'SAMPLING'}, '1x2', "SAMPLING is 1x2" );
is( $generic_header{'TELESCOPE'}, 'UKIRT', "TELESCOPE is UKIRT" );

# Translate the header back to specific headers.
my %specific_header = Astro::FITS::HdrTrans::translate_to_FITS( \%generic_header );
is( $specific_header{'TELESCOP'}, 'UKIRT, Mauna Kea, HI', "TELESCOP is UKIRT, Mauna Kea, HI" );


sub readfits {
  my $file = shift;
  open my $fh, "<", $file or die "Error opening header file $file: $!";
  my @cards = <$fh>;
  close $fh;
  return new Astro::FITS::Header( Cards => \@cards );
}
