use Test::More tests => 14;
use Test::Exception;
use strict;

my $CLASS;
BEGIN {
    unshift @INC => 'blib/lib/', '../blib/lib/';
    $CLASS = 'AI::NeuralNet::Simple';
    use_ok($CLASS) || die; 
};

can_ok($CLASS, 'new');

my $net1 = $CLASS->new(2,1,2);
ok($net1, 'Calling new with good arguments should succeed');
isa_ok($net1, $CLASS => '...and the object it returns');

can_ok($net1, 'learn_rate');
is(sprintf("%.1f", $net1->learn_rate), "0.2", '... and it should have the correct learn rate');
isa_ok($net1->learn_rate(.5), $CLASS => '... and setting it should return the object');
is(sprintf("%.1f", $net1->learn_rate), "0.5", '... and should set it correctly');

my $net2 = $CLASS->new(5,8,2);
ok($net2, 'Calling new with good arguments should succeed');
isa_ok($net2, $CLASS => '...and the object it returns');

can_ok($net2, 'learn_rate');
is(sprintf("%.1f", $net2->learn_rate), "0.2", '... and it should have the correct learn rate');
isa_ok($net2->learn_rate(.3), $CLASS => '... and setting it should return the object');
is(sprintf("%.1f", $net2->learn_rate), "0.3", '... and should set it correctly');
$net2->learn_rate(.2);

