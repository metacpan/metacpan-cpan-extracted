#! perl

use Test2::V0;
use CXC::Number::Grid qw( overlay_n );

use constant Grid => 'CXC::Number::Grid';

sub Failure { join( '::', 'CXC::Number::Grid::Failure', @_ ) }


subtest 'overlap' => sub {

    subtest 'as is' => sub {

        #<<< no tidy
        my $grid1 = Grid->new( edges   => [ 0,  1,   3,   5 ],
                               include => [   0,   0,   0   ] );
        my $grid2 = Grid->new( edges   => [        2,   4   ],
                               include => [           1     ] );
        #>>> ydit on

        my $gridN = overlay_n( $grid1, $grid2 );

        is(
            $gridN,
            object {
                call bin_edges => array { item number $_ for 0, 1, 2, 4, 5 };
                call include => array { item number $_ for 0, 0, 1, 0 };
            },
        );

    };

    subtest 'snap to overlay' => sub {

        my $grid1
          = Grid->new( edges => [ 0, 1, 2, 3 ], include => [ 0, 0, 0 ] );
        my $grid2 = Grid->new( edges => [ 1.1, 2.2 ], include => [1] );
        my $grid3 = Grid->new( edges => [ 2.3, 3.4 ], include => [0] );

        my $gridN = overlay_n( $grid1, $grid2, $grid3,
            { snap_dist => 0.1, snap_to => 'overlay' } );

        # grid1 < grid 2
        #  before snap
        #    edges : [ 0, 1, 1.1, 2.2, 3 ]
        #    layers: [ 1, 1, 2, 1 ]
        #    include: [ 0, 0, 1, 0 ]
        #  after snap
        #    edges : [ 0, 1.1, 2.2, 3 ]
        #    layers: [ 1, 2, 1 ]
        #    include: [ 0, 1, 0 ]

        # grid1 < grid 2 < grid 3
        #  before snap
        #    edges : [ 0, 1.1, 2.2, 2.3, 3.4 ]
        #    layers: [ 1, 1, 1, 3 ]
        #    include: [ 0, 1, 0, 0 ]
        #  after snap
        #    edges : [ 0, 1.1, 2.3, 3.4 ]
        #    layers: [ 1, 1, 3 ]
        #    include: [ 0, 1, 0 ]

        is(
            $gridN,
            object {
                call bin_edges => array { item number $_ for 0, 1.1, 2.3, 3.4 };
                call include => array { item number $_ for 0, 1, 0 };
            },
        );

    };

    subtest 'snap to underlay' => sub {

        my $grid1
          = Grid->new( edges => [ 0, 1, 2, 3 ], include => [ 0, 0, 0 ] );
        my $grid2 = Grid->new( edges => [ 1.1, 1.9 ], include => [1] );

        my $gridN = overlay_n( $grid1, $grid2,
            { snap_dist => 0.1, snap_to => 'underlay' } );

        # grid1 < grid 2
        #  before snap
        #    edges : [ 0, 1, 1.1, 1.9, 2, 3 ]
        #    layers: [ 1, 1, 2, 1, 1 ]
        #    include: [ 0, 0, 1, 0, 0 ]
        #  after snap (1)
        #    edges : [ 0, 1, 1.9, 2, 3 ]
        #    layers: [ 1, 2, 1, 1 ]
        #    include: [ 0, 1, 0, 0 ]
        #  after snap (2)
        #    edges : [ 0, 1, 2, 3 ]
        #    layers: [ 1, 2, 1 ]
        #    include: [ 0, 1, 0 ]

        is(
            $gridN,
            object {
                call bin_edges => array { item number $_ for 0, 1, 2, 3 };
                call include => array { item number $_ for 0, 1, 0 };
            },
        );

    };

};

subtest 'isolated' => sub {

    my $grid1 = Grid->new( edges => [ 0, 1, 2, 3 ], include => [ 1, 1, 1 ] );
    my $grid2 = Grid->new( edges => [ 4, 5 ], include => [1] );

    my $gridN = overlay_n( $grid1, $grid2 );

    is(
        $gridN,
        object {
            call bin_edges => array { item number $_ for 0, 1, 2, 3, 4, 5 };
            call include => array { item number $_ for 1, 1, 1, 0, 1 };
        },
    );

};

done_testing;
