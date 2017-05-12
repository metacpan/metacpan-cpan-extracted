use Test::More tests => 1;

use strict;
use warnings;

use PDL;

use Astro::FITS::CFITSIO::Simple qw/ :all /;

BEGIN { require 't/common.pl'; }

my $file = 'data/f003.fits';

# find the image in the haystack
eval {

    rdfits( $file, { hdutype => 'image'  } );
};
ok ( ! $@, "find image extension" ) or diag( $@ );
