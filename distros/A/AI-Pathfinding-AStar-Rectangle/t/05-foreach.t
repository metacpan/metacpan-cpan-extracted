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
    $a = "TODO_a";
    $b = "TODO_b";
    $_ = "TODO__";

    my $ok = 1;
    $m->foreach_xy( sub {$ok &&= defined $a && defined $b && defined $_ && $_ == 0; } );
    is( $ok, 1, "foreach on empty");

    is( $a, "TODO_a", '$a remain value' );
    is( $b, "TODO_b", '$b remain value' );
    is( $_, "TODO__", '$_ remain value' );

    $ok = 1;
    $m->foreach_xy_set( sub { $ok &&= defined $a && defined $b && defined $_ && $_ == 0 ; $a %2 } );
    
    is( $ok, 1 , '$a, $b, $_ defined and right');
    is( $a, "TODO_a", '$a remain value' );
    is( $b, "TODO_b", '$b remain value' );
    is( $_, "TODO__", '$_ remain value' );

    $ok = 1;
    $m->foreach_xy( sub {$ok &&= defined $a && defined $b && defined $_ && $_ == $a %2 ; } );
    is( $ok, 1, "foreach on even \$a");
    is( $m->get_passability( 0,0 ), 0, "(0,0)");
    is( $m->get_passability( 0,1 ), 0, "(0,1)");
    is( $m->get_passability( 1,0 ), 1, "(1,0)");
    is( $m->get_passability( 1,1 ), 1, "(1,1)");

    my $q = $m->clone();
    $ok = 1;
    $q->foreach_xy( sub {$ok &&= defined $a && defined $b && defined $_ && $_ == $a %2 ; } );
    is( $ok, 1, "foreach on cloned");
    ok( $q != $m , "clone is different" );
    is( $q->width, $m->width, "clone width");
    is( $q->height, $m->height, "clone height");
    is( $q->start_x, $m->start_x, "clone start_x");
    is( $q->start_y, $m->start_y, "clone start_y");
    is( $q->last_x, $m->last_x, "clone last_x");
    is( $q->last_y, $m->last_y, "clone last_y");



    $q = $m->clone_rect( 1, 1, 2, 3);
    $ok = 1;
    $q->foreach_xy( sub {$ok &&= defined $a && defined $b && defined $_ && $_ == $a %2 ; } );
    is($ok, 1, "foreach on rect clone" );
    ok( $q != $m, "rect clone is different" );

    is( $q->width, 2, "clone width");
    is( $q->height, 3, "clone height");
    is( $q->start_x, 1, "clone start_x");
    is( $q->start_y, 1, "clone start_y");
    is( $q->last_x, 2, "clone last_x");
    is( $q->last_y, 3, "clone last_y");




}
