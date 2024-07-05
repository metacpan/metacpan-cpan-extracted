use strict;
use warnings;

use Data::Random::Person;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Random::Person->new(
	'num_people' => 1,
);
my @ret = $obj->random;
is(@ret, 1, 'Get random people records count (1).');
isa_ok($ret[0], 'Data::Person');
