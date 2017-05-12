use Test::More tests => 22;
use Test::Exception;
use strict;

my $CLASS;
BEGIN {
    unshift @INC => 'blib/lib/', '../blib/lib/';
    $CLASS = 'AI::NeuralNet::Simple';
    use_ok($CLASS) || die; 
};

can_ok($CLASS, 'new');

throws_ok {$CLASS->new}
    qr/^\QYou must supply three positive integers to new()\E/,
    '... and calling it without arguments should die';

throws_ok {$CLASS->new(qw/foo bar 2/)}
    qr/^\QArguments to new() must be positive integers\E/,
    '... and supplying new() with bad arguments should also die';

my $net = $CLASS->new(2,1,2);
ok($net, 'Calling new with good arguments should succeed');
isa_ok($net, $CLASS => '...and the object it returns');

can_ok($net, 'learn_rate');
throws_ok {$net->learn_rate(2)}
    qr/^\QLearn rate must be between 0 and 1, exclusive\E/,
    '... and setting it outside of legal boundaries should die';
is(sprintf("%.1f", $net->learn_rate), "0.2", '... and it should have the correct learn rate');
isa_ok($net->learn_rate(.3), $CLASS => '... and setting it should return the object');
is(sprintf("%.1f", $net->learn_rate), "0.3", '... and should set it correctly');
$net->learn_rate(.2);

can_ok($net, 'train');

# teach the network logical 'or'

ok($net->train([1,1], [0,1]), 'Calling train() with valid data should succeed');
for (1 .. 10000) {
    $net->train([1,1],[0,1]);
    $net->train([1,0],[0,1]);
    $net->train([0,1],[0,1]);
    $net->train([0,0],[1,0]);
}

can_ok($net, 'winner');
is($net->winner([1,1]), 1, '... and it should return the index of the highest valued result');
is($net->winner([1,0]), 1, '... and it should return the index of the highest valued result');
is($net->winner([0,1]), 1, '... and it should return the index of the highest valued result');
is($net->winner([0,0]), 0, '... and it should return the index of the highest valued result');

# teach the network logical 'and' using the tanh() activation with delta=2
$net = $CLASS->new(2,1,2);
$net->delta(2);
$net->use_bipolar(1);
my $mse = $net->train_set([
	[1,1] => [0,1],
	[1,0] => [1,0],
	[0,1] => [1,0],
	[0,0] => [1,0],
], 10000, 0.2);

is($net->winner([1,1]), 1, '1 AND 1 = 1');
is($net->winner([1,0]), 0, '1 AND 0 = 0');
is($net->winner([0,1]), 0, '0 AND 1 = 0');
is($net->winner([0,0]), 0, '0 AND 0 = 0');
