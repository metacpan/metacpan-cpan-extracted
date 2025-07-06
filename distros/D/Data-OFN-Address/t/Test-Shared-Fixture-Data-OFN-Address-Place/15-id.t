use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;
use Test::Shared::Fixture::Data::OFN::Address::Place;

# Test.
my $obj = Test::Shared::Fixture::Data::OFN::Address::Place->new;
is($obj->id, undef, 'Get id (undef - default).');

# Test.
$obj = Test::Shared::Fixture::Data::OFN::Address::Place->new(
	'id' => 10,
);
is($obj->id, 10, 'Get id (10).');
