use strict;
use warnings;

use Data::OFN::Address;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Address->new;
is($obj->district, undef, 'Get district (undef).');

# Test.
$obj = Data::OFN::Address->new(
	'district' => 'https://linked.cuzk.cz/resource/ruian/okres/3804',
);
is($obj->district, 'https://linked.cuzk.cz/resource/ruian/okres/3804',
	'Get district (https://linked.cuzk.cz/resource/ruian/okres/3804).');
