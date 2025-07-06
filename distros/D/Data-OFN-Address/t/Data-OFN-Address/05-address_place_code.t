use strict;
use warnings;

use Data::OFN::Address;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Address->new;
is($obj->address_place_code, undef, 'Get address place code (undef).');

# Test.
$obj = Data::OFN::Address->new(
	'address_place_code' => 123,
);
is($obj->address_place_code, 123, 'Get address place code (123).');
