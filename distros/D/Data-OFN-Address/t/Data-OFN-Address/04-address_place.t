use strict;
use warnings;

use Data::OFN::Address;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Address->new;
is($obj->address_place, undef, 'Get address place (undef).');

# Test.
$obj = Data::OFN::Address->new(
	'address_place' => 'https://linked.cuzk.cz/resource/ruian/adresni-misto/123',
);
is($obj->address_place,
	'https://linked.cuzk.cz/resource/ruian/adresni-misto/123',
	'Get address place (https://linked.cuzk.cz/resource/ruian/adresni-misto/123).');
