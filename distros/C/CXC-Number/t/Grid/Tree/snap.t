#! perl

use Test2::V0;

use CXC::Number::Grid::Tree;

use constant Tree => 'CXC::Number::Grid::Tree';

subtest 'snap' => sub {

    my $tree = Tree->new;

    # initial layer
    $tree->range_set( 0, 1, [ 1, 0 ] );
    $tree->range_set( 1, 2, [ 1, 0 ] );
    $tree->range_set( 2, 3, [ 1, 0 ] );

    is(
        $tree->to_array,
        array {
            item [ 0, 1, [ 1, 0 ] ];
            item [ 1, 2, [ 1, 0 ] ];
            item [ 2, 3, [ 1, 0 ] ];
            end;
        },
        'layer 1, as array',
    );


    # unlink in overlay.t, use 0.2 & 1.2 instead of  0.1 & 1.1.
    # we're not using BigFloat here, and 0.1 & 1.1 cause the tests to fail,
    # as using standard doubles, abs(1.1-1) != 0.1

    # second layer
    $tree->range_set( 1.2, 2.2, [ 2, 1 ] );

    is(
        $tree->to_array,
        array {
            item [ 0,   1,   [ 1, 0 ] ];
            item [ 1,   1.2, [ 1, 0 ] ];
            item [ 1.2, 2.2, [ 2, 1 ] ];
            item [ 2.2, 3,   [ 1, 0 ] ];
            end;
        },
        'layer 2, as array',
    );

    is(
        $tree->to_grid,
        object {
            call edges => [ 0, 1, 1.2, 2.2, 3 ];
            call include => [ 0, 0, 1, 0 ];
        },
        'layer 2, as grid',
    );

    $tree->snap_overlaid( 2, 'overlay', 0.25 );

    is(
        $tree->to_array,
        array {
            item [ 0,   1.2, [ 1, 0 ] ];
            item [ 1.2, 2.2, [ 2, 1 ] ];
            item [ 2.2, 3,   [ 1, 0 ] ];
            end;
        },
        '1+2 snapped, as array',
    ) or note $tree->to_string;

    $tree->range_set( 2.4, 3.4, [ 3, 0 ] );

    $tree->snap_overlaid( 3, 'overlay', 0.25 );

    is(
        $tree->to_array,
        array {
            item [ 0,   1.2, [ 1, 0 ] ];
            item [ 1.2, 2.4, [ 2, 1 ] ];
            item [ 2.4, 3.4, [ 3, 0 ] ];
            end;
        },
        '2+3 snapped, as array',
    ) or note $tree->to_string;
};

done_testing;
