use strict;
use warnings;

use Test::More tests=>4;

use_ok('Apache::Voodoo::Zombie') || BAIL_OUT($@);

my $zombie = Apache::Voodoo::Zombie->new("some::broken::pm","it's broke");
eval {
	$zombie->says("brains");
};

isa_ok($@,'Apache::Voodoo::Exception::Compilation');
is($@->module, "some::broken::pm","source module");
is($@->message,"it's broke","failure message");
