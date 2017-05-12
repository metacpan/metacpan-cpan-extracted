# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-RunningTotal.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More tests => 29;
BEGIN { use_ok('Data::RunningTotal') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# This test will use bug tracking as an example
my $rt;
ok($rt = Data::RunningTotal->new(dimensions => ["state", "priority", "iteration", "product"]));

# First use the inc/dec interface - add 3 open bugs at time 10, 20, 30
$rt->inc(10, weight => 5,  coords => ["open", "P1", "D18", "perl-mod"]);
$rt->inc(20, weight => 10, coords => ["open", "P1", "D18", "perl-mod"]);
$rt->inc(30, weight => 25, coords => ["open", "P2", "D18", "script"]);
$rt->inc(40, weight => 50, coords => ["resolved", "P3", "D18", "perl-mod"]);
$rt->dec(50, weight => 15, coords => ["open", "P1", "D18", "perl-mod"]);
$rt->dec(60, weight => 15, coords => ["open", "P2", "D18", "script"]);

# Check various times with all wildcards
cmp_ok($rt->getValue(15, coords => [undef, undef, undef, undef]), '==', 5);
cmp_ok($rt->getValue(29, coords => [undef, undef, undef, undef]), '==', 15);
cmp_ok($rt->getValue(30, coords => [undef, undef, undef, undef]), '==', 40);
cmp_ok($rt->getValue(31, coords => [undef, undef, undef, undef]), '==', 40);
cmp_ok($rt->getValue(40, coords => [undef, undef, undef, undef]), '==', 90);
cmp_ok($rt->getValue(55, coords => [undef, undef, undef, undef]), '==', 75);
cmp_ok($rt->getValue(100, coords => [undef, undef, undef, undef]), '==', 60);

# Check different selections
cmp_ok($rt->getValue(100, coords => [undef, "P1", undef, undef]), '==', 0);
cmp_ok($rt->getValue(100, coords => [undef, sub {$_[0] =~ /^P[12]/}, undef, undef]), '==', 10);
cmp_ok($rt->getValue(100, coords => ["open", sub {$_[0] =~ /^P[12]/}, undef, "script"]), '==', 10);
cmp_ok($rt->getValue(100, coords => ["resolved", undef, undef, "script"]), '==', 0);

# Get the get list interface
my $list = $rt->getChangeList(coords => ["open", undef, "D18", "perl-mod"]);
is_deeply($list, [[10, 5],[20, 15],[50,0]], "getChangeList partial");

$list = $rt->getChangeList(coords => [undef, undef, "D18", undef]);
is_deeply($list, [[10, 5],[20, 15],[30,40],[40,90],[50,75],[60,60]], "getChangeList full");

# New running total
ok($rt = Data::RunningTotal->new(dimensions => ["state", "priority", "iteration", "product"]));

my @items;
for my $i (0..4) {
  ok($items[$i] = $rt->newItem(weight => 1));
  $items[$i]->moveTo(10+$i, coords => ["open", "P$i", "D18", "perl-mod"]);
}

$items[0]->moveTo(20, coords => ["closed", "P2", "D18", "perl-mod"]);
$items[1]->moveTo(30, coords => ["open", "P4", "D18", "perl-mod"]);
$items[2]->moveTo(40, coords => ["open", "P2", "D18", "script"]);
$items[3]->moveTo(50, coords => ["open", "P3", "D19", "script"]);
$items[4]->moveTo(60, coords => ["open", "P3", "D19", "script"]);

cmp_ok($rt->getValue(60, coords => [undef, undef, undef, undef]), '==', 5);
cmp_ok($rt->getValue(70, coords => ["open", undef, undef, undef]), '==', 4);
cmp_ok($rt->getValue(70, coords => ["open", "P1", undef, undef]), '==', 0);
cmp_ok($rt->getValue(15, coords => ["open", "P1", undef, undef]), '==', 1);
cmp_ok($rt->getValue(70, coords => ["open", "P3", undef, undef]), '==', 2);

# And a history of open bugs
$list = $rt->getChangeList(coords => ["open", undef, undef, undef]);
is_deeply($list, [[10,1],[11,2],[12,3],[13,4],[14,5],[20,4]], "checking \"open\"");

$list = $rt->getChangeList(coords => ["open", undef, undef, "script"]);
is_deeply($list, [[40,1],[50,2],[60,3]], "checking \"script\"");

# Test combineChangeList
my $comb = $rt->combineChangeList($rt->getChangeList(coords => ["open", "P1", undef, undef]),
                                  $rt->getChangeList(coords => ["open", "P2", undef, undef]));
is_deeply($comb, [[11,1,0],[12,1,1],[30,0,1]], "checking combineChangeList");

                                  


1;
