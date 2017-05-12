# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
BEGIN { use_ok('DCOLLINS::ANN::Robot'); 
	use_ok('DCOLLINS::ANN::SimWorld'); };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

$network=new DCOLLINS::ANN::Robot ();

ok(defined $network, "new() works");
ok($network->isa("DCOLLINS::ANN::Robot"), "Right class");
ok($network->isa("AI::ANN"), "Right class");

$world=new DCOLLINS::ANN::SimWorld ();

ok(defined $world, "new() works");
ok($world->isa("DCOLLINS::ANN::SimWorld"), "Right class");

$retval=$world->run_robot($network);

ok(defined $retval, "run_robot() works");
ok(defined $retval->{'fitness'}, "run_robot() gives a fitness value");

