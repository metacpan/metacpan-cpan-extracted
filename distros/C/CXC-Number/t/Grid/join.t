#! perl

use Test2::V0;
use CXC::Number::Grid qw( join_n );

use constant Grid => 'CXC::Number::Grid';

sub Failure { join( '::', 'CXC::Number::Grid::Failure', @_ ) }


subtest 'interface' => sub {

    subtest 'gap' => sub {

        for my $gap (
            qw( shift-right
            shift-left
            snap-right
            snap-left
            snap-both
            include
            exclude
            ) )
        {
            ok(
                lives {
                    join_n( Grid->new( edges => [ 0 .. 3 ] ), { gap => $gap } )
                },
                "gap $gap"
            );
        }
    };


    subtest 'grids' => sub {

        subtest 'no grids' => sub {
            my $err = dies { join_n() };
            isa_ok( $err, [ Failure( 'parameter::interface' ) ], );
            like( $err, qr/no grids supplied/ );
        };

        subtest 'grids overlap too much' => sub {
            my $err = dies {
                join_n(
                    Grid->new( edges => [ 0, 1, 2, 3.2, 4 ] ),
                    Grid->new( edges => [ 3, 4, 5 ] ),
                )
            };
            isa_ok( $err, [ Failure( 'parameter::constraint' ) ], );
            like( $err, qr/overlaps/ );
        };


    };


};

subtest 'gap' => sub {

    # default is include
    is(
        join_n(
            Grid->new( edges => [ 1, 2, 3 ] ),
            Grid->new( edges => [ 4, 5, 6 ] ),
        ),
        object {
            prop blessed => Grid;
            call edges => [ 1, 2, 3, 4, 5, 6 ];
        },
        'default',
    );

    is(
        join_n(
            Grid->new( edges => [ 1, 2, 3 ] ),
            Grid->new( edges => [ 4, 5, 6 ] ),
            { gap => 'shift-right' },
        ),
        object {
            prop blessed => Grid;
            call edges => [ 2, 3, 4, 5, 6 ];
        },
        'shift-right',
    );

    is(
        join_n(
            Grid->new( edges => [ 1, 2, 3 ] ),
            Grid->new( edges => [ 4, 5, 6 ] ),
            { gap => 'shift-left' },
        ),
        object {
            prop blessed => Grid;
            call edges => [ 1, 2, 3, 4, 5 ];
        },
        'shift-left',
    );

    is(
        join_n(
            Grid->new( edges => [ 1, 2, 3 ] ),
            Grid->new( edges => [ 4, 5, 6 ] ),
            { gap => 'snap-right' },
        ),
        object {
            prop blessed => Grid;
            call edges => [ 1, 2, 4, 5, 6 ];
        },
        'snap-right',
    );

    is(
        join_n(
            Grid->new( edges => [ 1, 2, 3 ] ),
            Grid->new( edges => [ 4, 5, 6 ] ),
            { gap => 'snap-left' },
        ),
        object {
            prop blessed => Grid;
            call edges => [ 1, 2, 3, 5, 6 ];
        },
        'snap-left',
    );

    is(
        join_n(
            Grid->new( edges => [ 1, 2, 3 ] ),
            Grid->new( edges => [ 4, 5, 6 ] ),
            { gap => 'snap-both' },
        ),
        object {
            prop blessed => Grid;
            call edges => [ 1, 2, 3.5, 5, 6 ];
        },
        'snap-both',
    );

    is(
        join_n(
            Grid->new( edges => [ 1, 2, 3 ] ),
            Grid->new( edges => [ 4, 5, 6 ] ),
            { gap => 'include' },
        ),
        object {
            prop blessed => Grid;
            call edges => [ 1, 2, 3, 4, 5, 6 ];
            call include => [ 1, 1, 1, 1, 1 ];
        },
        'include',
    );

    is(
        join_n(
            Grid->new( edges => [ 1, 2, 3 ] ),
            Grid->new( edges => [ 4, 5, 6 ] ),
            { gap => 'exclude' },
        ),
        object {
            prop blessed => Grid;
            call edges => [ 1, 2, 3, 4, 5, 6 ];
            call include => [ 1, 1, 0, 1, 1 ];
        },
        'exclude',
    );

};

done_testing;
