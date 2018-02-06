#!perl

use 5.006;
use strict;
use warnings;

use Test::More;
use Test::Number::Delta;
use File::Spec;

# Load Astro::FITS::Header if we can.
eval {
  require Astro::FITS::Header;
};
if( $@ ) {
  plan skip_all => 'Test requires Astro::FITS::Header module';
} else {
  plan tests => 9;
}

# Test compilation.
require_ok( 'Astro::FITS::HdrTrans' );

# Read the header off disk.
# This header has missing AZ EL START values
my $datadir = File::Spec->catdir( 't', 'data' );
my $fits = readfits( File::Spec->catfile( $datadir, 'scuba2-2.hdr' ) );
die "Error reading FITS headers from scuba2-2.hdr"
  unless defined $fits;
my %hdr;
tie %hdr, "Astro::FITS::Header", $fits;

# Translate this header.
my %generic_header = Astro::FITS::HdrTrans::translate_from_FITS( \%hdr );

isa_ok( $generic_header{'UTSTART'}, "Time::Piece", "UTSTART" )
;
isa_ok( $generic_header{'UTEND'}, "Time::Piece", "UTEND" );

is( $generic_header{'INSTRUMENT'}, "SCUBA-2", "SCUBA-2");

delta_ok( $generic_header{'RA_BASE'}, 281.104488457644, "Check RA_BASE" );
delta_ok( $generic_header{'DEC_BASE'}, -1.66150199455579, "Check DEC_BASE" );

ok( !exists $generic_header{AZIMUTH_START}, "Missing azimuth start" );
delta_ok( $generic_header{AZIMUTH_END}, 127.225669719891, "End azimuth is present" );

is($generic_header{'DOME_OPEN'}, 1, 'DOME OPEN');

sub readfits {
  my $file = shift;
  open my $fh, "<", $file or die "Error opening header file $file: $!";
  my @cards = <$fh>;
  close $fh;
  return new Astro::FITS::Header( Cards => \@cards );
}
