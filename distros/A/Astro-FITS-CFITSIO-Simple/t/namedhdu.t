#! perl

use Test2::V0 '!float';
use Test::Lib;

use PDL::Lite;

use Astro::FITS::CFITSIO::Simple qw/ :all /;

use My::Test::common;

my $file = 'data/f001.fits';

{
    my $msg = "extname";
    my @data;
    eval {
        @data = rdfits( $file, @simplebin_cols, { extname => 'raytrace' } );
    };

    ok( !$@, $msg ) or diag( $@ );


    chk_simplebin_piddles( $msg, @data );
}


{
    my $msg = "hdunum";
    my @data;
    eval { @data = rdfits( $file, @simplebin_cols, { hdunum => 2 } ); };

    ok( !$@, $msg ) or diag( $@ );


    chk_simplebin_piddles( $msg, @data );
}

{
    my $msg = "hdunum - nonexistant";
    eval { rdfits( $file, @simplebin_cols, { hdunum => 30 } ); };

    ok( $@, $msg );
}

{
    my $msg = "hdunum - not a table";
    eval { rdfits( $file, @simplebin_cols, { hdunum => 1 } ); };

    ok( $@, $msg );
}

done_testing;
