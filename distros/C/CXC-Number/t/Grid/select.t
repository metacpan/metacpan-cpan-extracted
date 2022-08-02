#! perl

use Test2::V0;
use CXC::Number::Grid qw( join_n );

use constant Grid => 'CXC::Number::Grid';

sub Failure { join( '::', 'CXC::Number::Grid::Failure', @_ ) }

is(
    Grid->new(
        edges   => [ 0 .. 11 ],
        include => [ ( 1 ) x 11 ],
    ),
    object {
        prop blessed => Grid;
        call min       => 0;
        call max       => 11;
        call nbins     => 11;
        call nedges    => 12;
        call edges     => [ 0 .. 11 ];
        call include   => [ ( 1 ) x 11 ];
        call bin_edges => [ 0 .. 11 ];
    },
    'baseline'
);

subtest constraints => sub {

    isa_ok(
        dies {
            Grid->new( edges => [ 1, 2, 3 ], include => [ 1, ] )
        },
        [ Failure( 'parameter::interface' ) ],
        q(too few include bits)
    );

    isa_ok(
        dies {
            Grid->new( edges => [ 1, 2, 3 ], include => [ 1, 1, 1 ] )
        },
        [ Failure( 'parameter::interface' ) ],
        q(too many include bits)
    );

    isa_ok(
        dies {
            Grid->new( edges => [ 1, 2, 3 ], include => [ 1, 2 ] )
        },
        ['Error::TypeTiny::Assertion'],
        q(incorrect bit value)
    );

    isa_ok(
        dies {
            Grid->new( edges => [ 1, 2, 3 ], include => [ 1, 'a' ] )
        },
        ['Error::TypeTiny::Assertion'],
        q(incorrect bit value)
    );

};

done_testing;
