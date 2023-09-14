use strict;
use warnings;

use Data::HashType;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Data::HashType->new(
	'name' => 'SHA1',
);
is($obj->active, 1, 'Get active flag (1 - default).');

# Test.
$obj = Data::HashType->new(
	'active' => 1,
	'name' => 'SHA1',
);
is($obj->active, 1, 'Get active flag (1).');

# Test.
$obj = Data::HashType->new(
	'active' => 0,
	'name' => 'SHA1',
);
is($obj->active, 0, 'Get active flag (0).');
