use strict;
use warnings;

use Data::Login::Role;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Data::Login::Role->new(
	'role' => 'admin',
);
is($obj->role, 'admin', 'Get role (admin).');
