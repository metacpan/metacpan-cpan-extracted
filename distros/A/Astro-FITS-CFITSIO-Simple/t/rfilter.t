#! perl

use Test2::V0 '!float';
use Test::Lib;

use PDL;

use Astro::FITS::CFITSIO::Simple qw/ :all /;

use My::Test::common;

my $file = 'data/f001.fits';

eval {
    my $rt_x = rdfits( $file, 'rt_x', { ninc => 1, rfilter => 'rt_y < 20' } );

    ok( ( $rt_x == pdl( 0 .. 9 ) )->all, "rfilter" );
};
ok( !$@, "rfilter" ) or diag( $@ );


eval {
    my %data = rdfits( $file, 'rt_x',
        { ninc => 1, rethash => 1, rfilter => 'rt_y < 20' } );

    ok( ( $data{rt_x} == pdl( 0 .. 9 ) )->all, "rfilter/rethash" );
};
ok( !$@, "rfilter/rethash" ) or diag( $@ );

eval {
    my %data = rdfits( $file, 'rt_x',
        { ninc => 1, retinfo => 1, rfilter => 'rt_y < 20' } );

    ok( ( $data{rt_x}{data} == pdl( 0 .. 9 ) )->all, "rfilter/retinfo" );
};
ok( !$@, "rfilter/retinfo" ) or diag( $@ );

done_testing;
