#! perl

use Test2::V0;

use aliased 'CXC::Number::Grid';

subtest 'all excludes' => sub {

    my $grid = Grid->new(
        edges   => [ 0 .. 11 ],
        include => [ ( 0 ) x 11 ],
    );
    my @grids = $grid->split;
    is( scalar @grids, 0, 'no splits' );
};

subtest 'no excludes' => sub {

    my $grid = Grid->new(
        edges   => [ 0 .. 11 ],
        include => [ ( 1 ) x 11 ],
    );
    my @grids = $grid->split;
    is( scalar @grids, 1, 'one grid' );

    is( $grids[0]->_raw_edges, $grid->_raw_edges, 'raw edges' );
    is( $grids[0]->_include,   $grid->_include,   'include' );
    is( $grids[0]->oob,        $grid->oob,        'oob' );
};

subtest 'lead excludes' => sub {

    my $grid = Grid->new(
        edges   => [ 0 .. 11 ],
        include => [ 0, 0, 0, ( 1 ) x ( 11 - 3 ) ],
    );
    my @grids = $grid->split;
    is( scalar @grids, 1, 'one grid' );

    is( $grids[0]->nbins, $grid->nbins - 3, 'nbins' );

    is(
        $grids[0]->_raw_edges,
        [ $grid->_raw_edges->@[ 3 .. 11 ] ],
        'raw edges'
    );
    is( $grids[0]->_include, [ $grid->_include->@[ 3 .. 10 ] ], 'include' );
    is( $grids[0]->oob,      $grid->oob,                        'oob' );

};

subtest 'trail excludes' => sub {

    my $grid = Grid->new(
        edges   => [ 0 .. 11 ],
        include => [ ( 1 ) x ( 11 - 3 ), 0, 0, 0 ],
    );
    my @grids = $grid->split;
    is( scalar @grids, 1, 'one grid' );

    is( $grids[0]->nbins, $grid->nbins - 3, 'nbins' );

    is(
        $grids[0]->_raw_edges,
        [ $grid->_raw_edges->@[ 0 .. ( 11 - 3 ) ] ],
        'raw edges'
    );
    is( $grids[0]->_include, [ $grid->_include->@[ 0 .. ( 10 - 3 ) ] ],
        'include' );
    is( $grids[0]->oob, $grid->oob, 'oob' );

};

subtest 'mixed excludes' => sub {

    my $grid = Grid->new(
        edges   => [ 0 .. 11 ],
        include => [ 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 0 ],
    );
    my @grids = $grid->split;
    is( scalar @grids, 2, 'two grids' );

    subtest 'split 0' => sub {

        is( $grids[0]->nbins, 3, 'nbins' );

        is(
            $grids[0]->_raw_edges,
            [ $grid->_raw_edges->@[ 3 .. 6 ] ],
            'raw edges'
        );
        is( $grids[0]->_include, [ $grid->_include->@[ 3 .. 5 ] ], 'include' );

        is( $grids[0]->oob, $grid->oob, 'oob' );
    };

    subtest 'split 1' => sub {

        is( $grids[1]->nbins, 2, 'nbins' );

        is(
            $grids[1]->_raw_edges,
            [ $grid->_raw_edges->@[ 8 .. 10 ] ],
            'raw edges'
        );
        is( $grids[1]->_include, [ $grid->_include->@[ 8 .. 9 ] ], 'include' );

        is( $grids[1]->oob, $grid->oob, 'oob' );
    };

};


done_testing;
