#! perl

use Test2::V0 '!float';
use Test::Lib;

use PDL;
use Astro::FITS::CFITSIO::Simple qw/ :all /;

use My::Test::common;

my $file = 'data/image.fits';

# success
eval {
    foreach my $type ( float, double, short, long, ushort, byte ) {
        my $img = rdfits( $file, { dtype => $type } );

        ok( $type == $img->type, "dtype: $type" );
    }
};
ok( !$@, "dtype" ) or diag( $@ );


# failure
foreach ( 5, 'snack' ) {
    eval { rdfits( $file, { dtype => $_ } ); };
    like( $@, qr/not a 'PDL::Type'/, "dtype: bad type $_" );
}

done_testing;
