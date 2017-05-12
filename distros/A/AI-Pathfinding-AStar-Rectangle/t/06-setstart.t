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
    $m->set_start_xy(-1, 0);
    is( $m->begin_x, -1, "begin_x (1)");
    is( $m->begin_y,  0, "begin_y (1)");
    is( $m->start_x, -1, "start_x (1)");
    is( $m->start_y,  0, "start_y (1)");

    is( $m->end_x, 3, "end_x (2)");
    is( $m->end_y,  4, "end_y (2)");
    is( $m->last_x, 3, "last_x (2)");
    is( $m->last_y,  4, "last_y (2)");



    $m->set_start_xy( 0, -1);
    is( $m->begin_x,   0, "begin_x (3)");
    is( $m->begin_y,  -1, "begin_y (3)");
    is( $m->start_x,   0, "start_x (3)");
    is( $m->start_y,  -1, "start_y (3)");

    is( $m->end_x,   4, "end_x (4)");
    is( $m->end_y,   3, "end_y (4)");
    is( $m->last_x,  4, "last_x (4)");
    is( $m->last_y,  3, "last_y (4)");


}
