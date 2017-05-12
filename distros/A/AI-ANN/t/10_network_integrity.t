# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 10;
BEGIN { use_ok('AI::ANN');
	use_ok('AI::ANN::Neuron'); };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

$network=new AI::ANN ('inputs'=>1, 'data'=>[{ iamanoutput => 0, inputs => {0 => 2}, neurons => {}},
                       { iamanoutput => 1, inputs => {}, neurons => {0 => 2}}], 'maxvalue' => 10);

ok(defined $network, "new() works");
ok($network->isa("AI::ANN"), "Right class");

ok($out=$network->execute([1]), "executed and still alive");

is($#{$out}, 0, "execute() output for two neurons is the right length");
is($out->[0], 4, "execute() output for two neurons has the correct value");

$data = $network->get_internals();

$data->[1]->{'iamanoutput'} = 0;
$data->[1]->{'inputs'}->[0] = 8;
$data->[1]->{'neurons'}->[0] = 0;

ok($out=$network->execute([1]), "executed and still alive");

is($#{$out}, 0, "execute() output for two neurons is the right length");
is($out->[0], 4, "execute() output for two neurons has the correct value");

