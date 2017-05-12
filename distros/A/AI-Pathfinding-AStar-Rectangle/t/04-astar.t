#!perl
use Test::More 'no_plan';
1 for $Test::More::TODO;
use Data::Dumper;

my $T;

BEGIN {
    $T = "AI::Pathfinding::AStar::Rectangle";
    eval "use ExtUtils::testlib;" unless grep { m/testlib/ } keys %INC;
    eval "use $T";
}

{
    my $m = $T->new( { width => 5, height => 5 } );
    for my $d ( "0" .. "9" ) {

        #    is_deeply([$m->validate_path(0,0,$d)], ['']);
        #    print Dumper([$m->validate_path(0,0,$d)], ['']);
    }

    $m->set_start_xy( 2, 5 );

    for my $x ( 2 .. 6 ) {
        for my $y ( 5 .. 9 ) {
            $m->set_passability( $x, $y, 1 );
        }
    }
    is_deeply( [ $m->astar( 2, 5, 2, 5 ) ], [ '',  1 ], "empty path" );
    is_deeply( [ $m->astar( 2, 5, 2, 6 ) ], [ '2', 1 ], " path= 8" );
    is_deeply( [ $m->astar( 2, 5, 3, 5 ) ], [ '6', 1 ], " path= 6" );
    is_deeply( [ $m->astar( 2, 5, 3, 6 ) ], [ '3', 1 ], " path= 9" );

    for ( split "", 14789 ) {
        my ( $x, $y ) = $m->path_goto( 2, 5, $_ );
        is_deeply( [ $m->astar( 2, 5, $x, $y ) ], [""], "no path" );
    }
    for ( split "", 12346789 ) {
        my ( $x, $y ) = $m->path_goto( 3, 6, $_ );
        print join " ", 3, 6, $x, $y, $_,"\n";
        is_deeply( [ $m->astar( 3, 6, $x, $y ) ], [ $_, 1 ], "curry" );
    }
    for ( split "", 12346789 ) {
        my ( $x, $y , $metric, $res) = $m->is_path_valid( 4, 7, $_ x 2 );
        is_deeply(
            [ $m->astar( 4, 7, $x, $y ) ],
            [ $_ x 2, 1 ],
            "curry 2"
        );
    }
}
