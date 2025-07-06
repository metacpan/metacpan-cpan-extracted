use strict;
use warnings;

use Data::OFN::Address;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Address->new;
is($obj->street, undef, 'Get street (undef - default).');

# Test.
$obj = Data::OFN::Address->new(
	'street' => 'https://linked.cuzk.cz/resource/ruian/ulice/309184',
);
is($obj->street, 'https://linked.cuzk.cz/resource/ruian/ulice/309184',
	'Get street (https://linked.cuzk.cz/resource/ruian/ulice/309184).');
