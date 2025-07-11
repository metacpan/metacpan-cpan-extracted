use strict;
use warnings;

use Data::OFN::Thing;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Thing->new;
is($obj->id, undef, 'Get id (undef - default).');

# Test.
$obj = Data::OFN::Thing->new(
	'id' => 7,
);
is($obj->id, 7, 'Get id (7).');
