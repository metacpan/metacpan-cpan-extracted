use Test::More tests => 2;

use strict;
use warnings;

use PDL;

use Astro::FITS::CFITSIO qw/ :constants /;
use Astro::FITS::CFITSIO::Simple qw/ :all /;
use Astro::FITS::CFITSIO::CheckStatus;

BEGIN { require 't/common.pl'; }

my $file = 'data/f003.fits';

tie my $status, 'Astro::FITS::CFITSIO::CheckStatus';

my $fptr = Astro::FITS::CFITSIO::open_file($file, READONLY,
			    $status = "could not open FITS file '$file'");

rdfits( $fptr, { hdutype => 'image', resethdu => 1  } );

$fptr->get_hdu_num( my $hdunum );

is ( $hdunum, 1 , "resethdu" );
is ( $fptr->perlyunpacking, -1, "perlyunpacking" );
