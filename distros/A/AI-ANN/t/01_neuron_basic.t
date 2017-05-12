# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 17;
BEGIN { use_ok('AI::ANN');
	use_ok('AI::ANN::Neuron'); };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

$neuron = new AI::ANN::Neuron(0, {0 => 1}, {});
ok(defined $neuron, "new() works");
ok($neuron->isa("AI::ANN::Neuron"), "Right class");

is($neuron->ready([1], {}), 1, "Ready - simplest case");
is($neuron->execute([1], {}), 1, "Execute - simplest case");

is($neuron->ready([], {}), 0, "Not ready - missing input");

is($neuron->ready([2, 0, 1], {}), 1, "Ready - extra inputs");
is($neuron->execute([2, 0, 1], {}), 2, "Execute - extra inputs");

is($neuron->ready([1], {0 => 2, 2 => 4}), 1, "Ready - extra neurons");
is($neuron->execute([1], {0 => 2, 2 => 4}), 1, "Execute - extra neurons");

$neuron = new AI::ANN::Neuron(0, {0 => 1, 1 => 3}, {1 => 3, 2 => 4});
ok(defined $neuron, "new() works on a more complex neuron");
ok($neuron->isa("AI::ANN::Neuron"), "Right class");

is($neuron->ready([1, 2], [undef, 1, 3]), 1, "Ready - complex case 1");
is($neuron->execute([1, 2], [0, 1, 3]), 22, "Execute - complex case 1");

is($neuron->ready([1, 2], [0, 1]), 0, "Not ready - complex case 2");

is($neuron->ready([2], [0, 1, 3]), 0, "Not ready - complex case 3");


