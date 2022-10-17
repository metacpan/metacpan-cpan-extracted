#! perl

use Test2::V0 '!float';
use Test::Lib;

use PDL;

use Astro::FITS::CFITSIO qw/ :constants /;
use Astro::FITS::CFITSIO::Simple qw/ :all /;
use Astro::FITS::CFITSIO::CheckStatus;

use My::Test::common;

my $file = 'data/f001.fits';

tie my $status, 'Astro::FITS::CFITSIO::CheckStatus';

my $fptr = Astro::FITS::CFITSIO::open_file( $file, READONLY,
    $status = "could not open FITS file '$file'" );

my %data;
eval { %data = rdfits( $fptr, '-rt_x' ); };

ok( !$@, "accepted subtractive field" );

ok( !exists $data{rt_x}, "subtracted field" );

done_testing;
