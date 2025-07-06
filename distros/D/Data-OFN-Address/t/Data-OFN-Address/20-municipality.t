use strict;
use warnings;

use Data::OFN::Address;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Address->new;
is($obj->municipality, undef, 'Get municipality (undef - default).');

# Test.
$obj = Data::OFN::Address->new(
	'municipality' => 'https://linked.cuzk.cz/resource/ruian/obec/599352',
);
is($obj->municipality, 'https://linked.cuzk.cz/resource/ruian/obec/599352',
	'Get municipality (https://linked.cuzk.cz/resource/ruian/obec/599352).');
