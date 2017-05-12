use Test::More tests => 1;

use strict;
use warnings;

use PDL::Lite;
use Astro::FITS::CFITSIO::Simple qw/ rdfits /;

my %pdls_ok;
eval { %pdls_ok = rdfits('data/zero_rows.fits') };
ok ( !$@, "read a zero row table" )
  or diag($@);
