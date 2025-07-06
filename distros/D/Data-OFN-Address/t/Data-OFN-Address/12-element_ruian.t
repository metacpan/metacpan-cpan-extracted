use strict;
use warnings;

use Data::OFN::Address;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Address->new;
is($obj->element_ruian, undef, 'Get ruian element (undef - default).');

# Test.
$obj = Data::OFN::Address->new(
	'element_ruian' => 'https://linked.cuzk.cz/resource/ruian/parcela/91188411010',
);
is($obj->element_ruian, 'https://linked.cuzk.cz/resource/ruian/parcela/91188411010',
	'Get ruian element (https://linked.cuzk.cz/resource/ruian/parcela/91188411010).');
