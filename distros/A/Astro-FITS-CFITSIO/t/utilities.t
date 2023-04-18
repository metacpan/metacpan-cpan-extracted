#! perl

use strict;
use warnings;

use Test2::V0;

use Astro::FITS::CFITSIO qw( :longnames :constants  );

# fits_get_keyname
subtest 'fits_get_keyname' => sub {
    fits_get_keyname( "TESTING  'This is a test'", my $name, undef, my $status = 0 );
    is( $name, 'TESTING', 'value' );
};

done_testing;
