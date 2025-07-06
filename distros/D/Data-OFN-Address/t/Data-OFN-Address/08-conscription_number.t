use strict;
use warnings;

use Data::OFN::Address;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Address->new;
is($obj->conscription_number, undef, 'Get conscription number (undef).');

# Test.
$obj = Data::OFN::Address->new(
	'conscription_number' => 123,
);
is($obj->conscription_number, 123, 'Get conscription number (123).');
