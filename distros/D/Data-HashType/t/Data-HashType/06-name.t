use strict;
use warnings;

use Data::HashType;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Data::HashType->new(
	'name' => 'SHA1',
);
is($obj->name, 'SHA1', 'Get name (SHA1).');
