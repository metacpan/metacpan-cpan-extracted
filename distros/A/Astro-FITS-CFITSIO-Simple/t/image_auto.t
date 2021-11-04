#! perl

use Test2::V0 '!float';
use Test::Lib;

use PDL;
use Astro::FITS::CFITSIO::Simple qw/ :all /;

use My::Test::common;

my $file = 'data/f003.fits';

# find the image in the haystack
eval {

    rdfits( $file, { hdutype => 'image'  } );
};
ok ( ! $@, "find image extension" ) or diag( $@ );

done_testing;