#! perl

use Test2::V0;

use experimental 'signatures';

use CXC::Number::Grid::Tree;

use constant Tree => 'CXC::Number::Grid::Tree';

sub fid_tree {
    my $tree = Tree->new;

    # these don't need to be contiguous, as the space between ranges
    # turns into another range with an undefined value, which is
    # turned into an excluded bin.  However, CXC::Number::Grid will
    # always create trees with truly contiguous bins.
    $tree->range_set( 0, 1, 0 );
    $tree->range_set( 1, 2, 1 );
    $tree->range_set( 2, 3, 0 );
    $tree->range_set( 3, 4, 1 );

    return $tree;
}

sub check_grid ( $grid ) {

    my $ctx = context;
    my $ok  = is(
        $grid,
        object {
            call edges => [ 0, 1, 2, 3, 4 ];
            call include => [ 0, 1, 0, 1 ];
        },
    );

    $ctx->release;
    return $ok;
}

sub check_array ( $array ) {

    my $ctx = context;

    my $ok = is(
        $array,
        array {
            item [ 0, 1, 0 ];
            item [ 1, 2, 1 ];
            item [ 2, 3, 0 ];
            item [ 3, 4, 1 ];
        },
    );

    $ctx->release;
    return $ok;
}


subtest 'to_grid' => sub {
    check_grid( fid_tree()->to_grid );
};

subtest 'to_array' => sub {
    check_array( fid_tree()->to_array );
};

subtest 'round trip' => sub {
    my $array = fid_tree()->to_array;
    check_grid( Tree->from_array( $array )->to_grid );

};


done_testing;
