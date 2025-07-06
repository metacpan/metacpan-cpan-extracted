use strict;
use warnings;

use Data::OFN::Address;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Address->new;
is($obj->house_number, undef, 'Get house number (undef - default).');

# Test.
$obj = Data::OFN::Address->new(
	'house_number' => 386,
);
is($obj->house_number, 386, 'Get house number (386).');
