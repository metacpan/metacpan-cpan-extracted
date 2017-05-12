#!perl
# Testing GSD read of fits headers

use strict;

use Test::More;

BEGIN {
  eval "use GSD;";
  if ($@) {
    plan skip_all => "GSD module not available";
    exit;
  } else {
    plan tests => 4;
  }
}

use File::Spec;
require_ok( "Astro::FITS::Header::GSD" );

# Read-only
# Try to work out whether the file is in the t directory or the parent
my $gsdfile = "test.gsd";

$gsdfile = File::Spec->catfile("t","test.gsd")
  unless -e $gsdfile;

my $hdr = new Astro::FITS::Header::GSD( File => $gsdfile );
ok( $hdr );

# Get the telescope name
my $item = $hdr->itembyname( 'C1TEL' );
is( $item->value, "JCMT", "Check C1TEL");
is( $item->type, "STRING", "Check C1TEL type" );
