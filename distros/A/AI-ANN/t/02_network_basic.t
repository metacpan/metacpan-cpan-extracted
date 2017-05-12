# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 25;
BEGIN { use_ok('AI::ANN');
	use_ok('AI::ANN::Neuron'); };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

$network=new AI::ANN ('inputs'=>1, 'data'=>[{ iamanoutput => 1, inputs => {0 => 1}, neurons => {}}], 'maxvalue' => 10);

ok(defined $network, "new() works");
ok($network->isa("AI::ANN"), "Right class");

ok($out=$network->execute([1]), "executed and still alive");

is($#{$out}, 0, "execute() output for a single neuron is the right length");
is($out->[0], 1, "execute() output for a single neuron has the correct value");

($inputs, $neurons, $outputs) = $network->get_state();

is($#{$inputs}, 0, "get_state inputs is correct length");
is($inputs->[0], 1, "get_state inputs returns correct element 0");

is($#{$neurons}, 0, "get_state neurons is correct length");
is($neurons->[0], 1, "get_state neurons returns correct element 0");

is($#{$outputs}, 0, "get_state outputs is correct length");
is($outputs->[0], 1, "get_state outputs returns correct element 0");

$network=new AI::ANN ('inputs'=>1, 'data'=>[{ iamanoutput => 0, inputs => {0 => 2}, neurons => {}},
                       { iamanoutput => 1, inputs => {}, neurons => {0 => 2}}], 'maxvalue' => 10);

ok(defined $network, "new() works");
ok($network->isa("AI::ANN"), "Right class");

ok($out=$network->execute([1]), "executed and still alive");

is($#{$out}, 0, "execute() output for two neurons is the right length");
is($out->[0], 4, "execute() output for two neurons has the correct value");

($inputs, $neurons, $outputs) = $network->get_state();

is($#{$inputs}, 0, "get_state inputs is correct length");
is($inputs->[0], 1, "get_state inputs returns correct element 0");

is($#{$neurons}, 1, "get_state neurons is correct length");
is($neurons->[0], 2, "get_state neurons returns correct element 0");
is($neurons->[1], 4, "get_state neurons returns correct element 1");

is($#{$outputs}, 0, "get_state outputs is correct length");
is($outputs->[0], 4, "get_state outputs returns correct element 0");

