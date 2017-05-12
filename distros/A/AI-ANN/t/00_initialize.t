# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
BEGIN { use_ok('AI::ANN');
	use_ok('AI::ANN::Neuron');
	use_ok('AI::ANN::Evolver'); };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

$network=new AI::ANN ('inputs' => 1, 'data' => [{ iamanoutput => 1, inputs => {0 => 1}, neurons => {}}]);

ok(defined $network, "new() works");
ok($network->isa("AI::ANN"), "Right class");

$neuron=new AI::ANN::Neuron (0, {0 => 1}, {});

ok(defined $neuron, "new() works");
ok($neuron->isa("AI::ANN::Neuron"), "Right class");

$evolver=new AI::ANN::Evolver ();

ok(defined $evolver, "new() works");
ok($evolver->isa("AI::ANN::Evolver"), "Right class");

