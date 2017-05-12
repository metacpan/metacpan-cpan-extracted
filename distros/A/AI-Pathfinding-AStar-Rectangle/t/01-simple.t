# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Map-XS.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 10+9+2+1;

1 for $Test::More::TODO;
our $T = 'AI::Pathfinding::AStar::Rectangle';
BEGIN{
    eval "use ExtUtils::testlib;" unless grep { m/::testlib/ } keys %INC;
    print "not ok $@" if $@;
    $T = 'AI::Pathfinding::AStar::Rectangle';
    eval "use $T qw(create_map);";
    die "Can't load $T: $@." if $@;
}
use AI::Pathfinding::AStar::Rectangle qw(create_map);

my $a= $T->new({ width => 12, height => 15 });
ok($a);
is(ref ($a), $T);
is(ref create_map({width=>1, height=>1}), $T);

is($a->width, 12, 'width');
is($a->height, 15, 'height');
is($a->start_x, 0, 'start_x of new map eq 0');
is($a->start_y, 0, 'start_y of new map eq 0');
is($a->last_x, 11, 'last_x of new map eq 0');
is($a->last_y, 14, 'last_y of new map eq 0');

my $s='';
$a->foreach_xy( sub {$s.=$_} );
is($s, ('0' x (12*15)));

$a->set_start_xy(40, 50 );
is($a->start_x, 40, 'start_x of map eq 40');
is($a->start_y, 50, 'start_y of map eq 50');

is($a->last_x, 40+11, 'last_x of map eq 51');
is($a->last_y, 50+14, 'last_y of map eq 64');

$s='';
$a->foreach_xy( sub {$s.=$_} );
is($s, ('0' x (12*15)));

$a->set_start_xy( -40, -50 );
is($a->start_x, -40, 'start_x of map eq -40');
is($a->start_y, -50, 'start_y of map eq -50');

is($a->last_x, -40+11, 'last_x of map eq -29');
is($a->last_y, -50+14, 'last_y of map eq -36');

$a->start_x(0);
is($a->start_x, 0, "set start x");

$a->start_y(0);
is($a->start_y, 0, "set start y");

# 10 + 8
my $s_1='';
$a->foreach_xy_set( sub { 1;} );
$a->foreach_xy( sub {$s_1.=$_} );
is($s_1, ('1' x (12*15)), "all 111");
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

