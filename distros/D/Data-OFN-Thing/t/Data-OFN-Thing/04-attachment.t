use strict;
use warnings;

use Data::OFN::Thing;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Thing->new;
is_deeply(
	$obj->attachment,
	[],
	'Get attachment ([] - default).',
);

