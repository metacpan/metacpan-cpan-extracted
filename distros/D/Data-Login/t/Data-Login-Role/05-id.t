use strict;
use warnings;

use Data::Login::Role;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Login::Role->new(
	'role' => 'admin',
);
is($obj->id, undef, 'Get id (undef - default).');

# Test.
$obj = Data::Login::Role->new(
	'id' => 10,
	'role' => 'admin',
);
is($obj->id, 10, 'Get id (10).');
