# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 21;
BEGIN { use_ok('DCOLLINS::ANN::Robot'); 
use_ok('AI::ANN::Evolver'); };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

$network=new DCOLLINS::ANN::Robot ();

ok(defined $network, "new() works");
ok($network->isa("AI::ANN"), "Right class");
ok($network->isa("DCOLLINS::ANN::Robot"), "Right class");

ok($out=$network->execute([1]), "executed and still alive");
is($#{$out}, 4, "execute() output for a single neuron is the right length");

($inputs, $neurons, $outputs) = $network->get_state();

is($#{$inputs}, 0, "get_state inputs is correct length");
is($#{$neurons}, 64, "get_state neurons is correct length");
is($#{$outputs}, 4, "get_state outputs is correct length");

$evolver=new AI::ANN::Evolver ({});

ok(defined $evolver, "new() works");
ok($evolver->isa("AI::ANN::Evolver"), "Right class");

$network3=$evolver->crossover($network, $network);

ok(defined $network3, "crossover() works");
ok($network3->isa("AI::ANN"), "Right class");
ok($network3->isa("DCOLLINS::ANN::Robot"), "Right class");


$network4=$evolver->mutate($network);

ok(defined $network4, "mutate() works");
ok($network4->isa("AI::ANN"), "Right class");
ok($network4->isa("DCOLLINS::ANN::Robot"), "Right class");


$network5=$evolver->mutate_gaussian($network);

ok(defined $network5, "mutate_gaussian() works");
ok($network5->isa("AI::ANN"), "Right class");
ok($network5->isa("DCOLLINS::ANN::Robot"), "Right class");


