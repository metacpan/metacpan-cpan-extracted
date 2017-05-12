# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Map-XS.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More 'no_plan';
use strict;
use warnings;

1 for $Test::More::TODO;
my $T;
BEGIN{
    eval "use ExtUtils::testlib;" unless grep { m/::testlib/ } keys %INC;
    print "not ok $@" if $@;
    $T = 'AI::Pathfinding::AStar::Rectangle';
    eval "use $T qw(create_map);";
    die "Can't load $T: $@." if $@;
}

my $m= $T->new({ width => 12, height => 15 });
my $accum;

$accum = '';
for my $x(-2..14){
    for my $y (-2..17){
        $accum.= $m->get_passability($x,$y);
    }
}
is($accum, ( '0' x (12*15)), "all 0");

$m->foreach_xy_set( sub { $a + 2 ;});
$accum = '';
$m->foreach_xy( sub {$accum.= 1 if ($a + 2) == $_;});
is($accum, ( '1' x (12*15)), "all 1 ");

$m->foreach_xy_set( sub { $b + 2 ;});
$accum = '';
$m->foreach_xy( sub {$accum.= 1 if ($b + 2) == $_;});
is($accum, ( '1' x (12*15)), "all 1 ");

$m->set_start_xy(-2, 2);
$m->foreach_xy_set( sub { $a + 2 ;});
$accum = '';
$m->foreach_xy( sub {$accum.= 1 if ($a + 2) == $_;});
is($accum, ( '1' x (12*15)), "all 1 ");

$m->foreach_xy_set( sub { $b + 2 ;});
$accum = '';
$m->foreach_xy( sub {$accum.= 1 if ($b + 2) == $_;});
is($accum, ( '1' x (12*15)), "all 1 ");




$m->set_start_xy(0,0);
my $count = 0;
$count = 0;
for my $x (0..11){
    for my $y (0..14){
        $count = ($count + 1) % 127 +1;
        $m->set_passability($x,$y, $count);
        is($m->get_passability($x,$y), $count, "check fix");
        $m->set_start_xy(13, 20);
        is($m->get_passability($x+13,$y+20), $count, "check fix with offset");
        $m->set_start_xy(0,0);
    }
}

$m=$T->new({ width => 12, height => 15 });
$count = 0;
for my $y (0..14){
    for my $x (0..11){
        ok(not $m->get_passability($x,$y));
        $count = ($count + 1) % 127 +1;
        $m->set_passability($x,$y, $count);

        is($m->get_passability($x,$y), $count, "check fix no offset");
        $m->set_start_xy(13, 20);
        is($m->get_passability($x+13,$y+20), $count, "check fix with offset");
        $m->set_start_xy(0,0);
    }
}

{

    my $m=$T->new({ width => 15, height => 12 });

    for my $y(-2..14){
        for my $x (-2..17){
            ok(not $m->get_passability($x,$y));
        }
    }
    $m->set_start_xy(0,0);
    my $count = 0;
    $count = 0;
    for my $y (0..11){
        for my $x (0..14){
            ok(not $m->get_passability($x,$y));
            $count = ($count + 1) % 127 +1;
            $m->set_passability($x,$y, $count);
            is($m->get_passability($x,$y), $count, "check fix");
            $m->set_start_xy(13, 20);
            is($m->get_passability($x+13,$y+20), $count, "check fix with offset");
            $m->set_start_xy(0,0);
        }
    }

    $m=$T->new({ width => 15, height => 12 });
    $count = 0;
    for my $x (0..14){
        for my $y (0..11){
            ok(not $m->get_passability($x,$y));
            $count = ($count + 1) % 127 +1;
            $m->set_passability($x,$y, $count);

            is($m->get_passability($x,$y), $count, "check fix no offset");
            $m->set_start_xy(13, 20);
            is($m->get_passability($x+13,$y+20), $count, "check fix with offset");
            $m->set_start_xy(0,0);
        }
    }
}
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

