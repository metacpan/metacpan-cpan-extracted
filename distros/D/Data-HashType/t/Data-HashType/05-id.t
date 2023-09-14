use strict;
use warnings;

use Data::HashType;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HashType->new(
	'name' => 'SHA1',
);
is($obj->id, undef, 'Get id (undef - default).');

# Test.
$obj = Data::HashType->new(
	'id' => 10,
	'name' => 'SHA1',
);
is($obj->id, 10, 'Get id (10).');
