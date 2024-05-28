use strict;
use warnings;

use Data::Person;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Person->new;
is($obj->id, undef, 'Get id (undef - default).');

# Test.
$obj = Data::Person->new(
	'id' => 1,
);
is($obj->id, 1, 'Get id (1).');
