use strict;
use warnings;

use Data::Login::Role;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Data::Login::Role->new(
	'role' => 'admin',
);
is($obj->active, 1, 'Get active (1 - default).');

# Test.
$obj = Data::Login::Role->new(
	'active' => 1,
	'role' => 'admin',
);
is($obj->active, 1, 'Get active (1).');

# Test.
$obj = Data::Login::Role->new(
	'active' => 0,
	'role' => 'admin',
);
is($obj->active, 0, 'Get active (0).');
