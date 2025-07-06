use strict;
use warnings;

use Data::OFN::Address;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Address->new;
is($obj->id, undef, 'Get id (undef - default).');

# Test.
$obj = Data::OFN::Address->new(
	'id' => 10,
);
is($obj->id, 10, 'Get id (10).');
