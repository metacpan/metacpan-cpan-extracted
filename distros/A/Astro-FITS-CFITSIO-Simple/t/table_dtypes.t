#! perl

use Test2::V0 '!float';
use Test::Lib;

use PDL;

use Astro::FITS::CFITSIO::Simple qw/ :all /;

use My::Test::common;

my $file = 'data/f001.fits';

# success
eval {
    foreach my $type ( float, double, short, long, ushort, byte ) {
        my %data = rdfits( $file, { ninc => 1, dtypes => { rt_x => $type } } );

        ok( $type == $data{rt_x}->type, "dtype: $type" );
    }
};
ok( !$@, "dtype" ) or diag( $@ );


# failure
foreach ( 5, 'snack' ) {
    eval { rdfits( $file, { ninc => 1, dtypes => { rt_x => $_ } } ); };
    like( $@, qr/user specified type/, "dtype: bad type $_" );
}

for ( qw/ rt_snackfood / ) {
    eval { rdfits( $file, { ninc => 1, dtypes => { $_ => float } } ); };
    like( $@, qr/not in file/, "dtype: bad column name $_" );
}

done_testing;
