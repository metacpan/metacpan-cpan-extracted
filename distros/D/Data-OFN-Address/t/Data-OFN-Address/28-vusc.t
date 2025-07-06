use strict;
use warnings;

use Data::OFN::Address;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Address->new;
is($obj->vusc, undef, 'Get vusc (undef - default).');

# Test.
$obj = Data::OFN::Address->new(
	'vusc' => 'https://linked.cuzk.cz/resource/ruian/vusc/132',
);
is($obj->vusc, 'https://linked.cuzk.cz/resource/ruian/vusc/132',
	'Get vusc (https://linked.cuzk.cz/resource/ruian/vusc/132).');
