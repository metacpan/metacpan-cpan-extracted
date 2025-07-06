use strict;
use warnings;

use Data::OFN::Address;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Address->new;
is($obj->conscription_number_flag, undef, 'Get conscription number flag (undef).');

# Test.
$obj = Data::OFN::Address->new(
	'conscription_number' => 123,
	'conscription_number_flag' => 'a',
);
is($obj->conscription_number_flag, 'a', 'Get conscription number flag (a).');
