use strict;
use warnings;

use Data::OFN::Address;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Address->new;
is($obj->mop, undef, 'Get mop (undef - default).');

# Test.
$obj = Data::OFN::Address->new(
	'mop' => 'https://linked.cuzk.cz/resource/ruian/mop/60',
);
is($obj->mop, 'https://linked.cuzk.cz/resource/ruian/mop/60',
	'Get mop (https://linked.cuzk.cz/resource/ruian/mop/60).');
