use strict;
use warnings;

use Data::OFN::Address;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Address->new;
is($obj->psc, undef, 'Get psc (undef - default).');

# Test.
$obj = Data::OFN::Address->new(
	'psc' => 74245,
);
is($obj->psc, '74245', 'Get psc (74245).');
