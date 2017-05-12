use Test::More tests => 15;
use Test::Exception;
use Storable;
use strict;

my $CLASS;
BEGIN {
    unshift @INC => 'blib/lib/', '../blib/lib/';
    $CLASS = 'AI::NeuralNet::Simple';
    use_ok($CLASS) || die; 
};

can_ok($CLASS, 'new');

my $net = $CLASS->new(2,1,2);
$net->delta(2);
$net->use_bipolar(5);
for (1 .. 10000) {
    $net->train([1,1],[0,1]);
    $net->train([1,0],[0,1]);
    $net->train([0,1],[0,1]);
    $net->train([0,0],[1,0]);
}

is($net->winner([1,1]), 1, '... and it should return the index of the highest valued result');
is($net->winner([1,0]), 1, '... and it should return the index of the highest valued result');
is($net->winner([0,1]), 1, '... and it should return the index of the highest valued result');
is($net->winner([0,0]), 0, '... and it should return the index of the highest valued result');

ok(store($net, "t/store"), "store() succeeds");
$net = undef;

$net = retrieve("t/store");
ok($net, "retrieve() succeeds");
unlink 't/store';
can_ok($net, 'learn_rate');
is($net->delta, 2, 'properly restored value of delta');
is($net->use_bipolar, 5, 'properly restored value of use_bipolar');

is($net->winner([1,1]), 1, '... and it should return the index of the highest valued result');
is($net->winner([1,0]), 1, '... and it should return the index of the highest valued result');
is($net->winner([0,1]), 1, '... and it should return the index of the highest valued result');
is($net->winner([0,0]), 0, '... and it should return the index of the highest valued result');
