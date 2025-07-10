use strict;
use warnings;

use Data::OFN::Common::Quantity;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Common::Quantity->new(
	'unit' => 'KGM',
	'value' => 10,
);
is($obj->unit, 'KGM', 'Get unit (KGM).');
