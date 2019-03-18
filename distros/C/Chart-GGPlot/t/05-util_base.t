#!perl

use Chart::GGPlot::Setup qw(:base :pdl);

# Test2::V0 also has a function called "match".
use Chart::GGPlot::Util qw(:all !match);

use Test2::V0 '!number';
use Test2::Tools::PDL;

pdl_is( sign( pdl( -5, 0, 2, "inf", "-inf", "nan" )->setbadat(5) ),
    pdl([ -1, 0, 1, 1, -1, 'nan' ])->setnantobad, 'sign()' );
ok( !is_null( pdl( [] ) ), 'is_null(pdl([]))' );
ok( is_null(null), 'is_null(null)' );

pdl_is( is_finite( pdl( "inf", "-inf", 42, -7.0, 'nan' ) ),
    pdl([ 0, 0, 1, 1, 0 ]), 'is_finite' );
pdl_is(
    is_infinite( pdl( "inf", "-inf", 42, -7.0, 'nan' ) ),
    pdl([ 1, 1, 0, 0, 0 ]),
    'is_infinite()'
);

subtest seq => sub {
    pdl_is( seq_by( 1, 3, 0.5 ), pdl([ 1, 1.5, 2, 2.5, 3 ]), "seq_by()" );

    pdl_is( seq_n( 1, 3, 5 ), pdl([ 1, 1.5, 2, 2.5, 3 ]), "seq_n()" );
    pdl_is( seq_n( 3, 1, 5 ), pdl([ 3, 2.5, 2, 1.5, 1 ]), "seq_n()" );
    pdl_is( seq_n( 15, 15, 1 ), pdl([ 15 ]), "seq_n()" );
};

subtest range_ => sub {
    pdl_is( range_( pdl( 1 .. 4 ) ), pdl( [ 1, 4 ] ), 'range_($pdl)' );
    pdl_is(
        range_(
            PDL::DateTime->new_from_datetime(
                [qw(2019-01-01 2019-02-01 2018-01-01)]
            )
        ),
        PDL::DateTime->new_from_datetime( [qw(2018-01-01 2019-02-01)] ),
        'range_($pdldt)'
    );
};

subtest match => sub {
    pdl_is(
        Chart::GGPlot::Util::match( pdl( [ 1, 2, 3 ] ), pdl( [ 3, 1, 2 ] ) ),
        pdl([ 1, 2, 0 ]),
        'match($pdl, $pdl)'
    );
    pdl_is(
        Chart::GGPlot::Util::match(
            PDL::SV->new( [qw(foo bar baz)] ),
            PDL::SV->new( [qw(baz foo bar)] )
        ),
        pdl([ 1, 2, 0 ]),
        'match($pdlsv, $pdlsv)'
    );
    pdl_is(
        Chart::GGPlot::Util::match(
            PDL::Factor->new(
                [qw(6 6 4 6 8 6 8 4 4 6)], levels => [qw(8 6 4)]
            ),
            PDL::Factor->new( [qw(8 6 4)] ),
        ),
        pdl( [qw(1 1 2 1 0 1 0 2 2 1)] ),
        'match($factor, $factor)'
    );
};

done_testing();
