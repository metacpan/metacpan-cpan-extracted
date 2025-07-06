use strict;
use warnings;

use Data::OFN::Address;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Address->new;
is($obj->municipality_part, undef, 'Get municipality part (undef - default).');

# Test.
$obj = Data::OFN::Address->new(
	'municipality_part' => 'https://linked.cuzk.cz/resource/ruian/cast-obce/413551',
);
is($obj->municipality_part, 'https://linked.cuzk.cz/resource/ruian/cast-obce/413551',
	'Get municipality part (https://linked.cuzk.cz/resource/ruian/cast-obce/413551).');
