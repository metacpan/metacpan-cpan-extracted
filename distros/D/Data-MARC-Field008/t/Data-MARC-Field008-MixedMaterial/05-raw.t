use strict;
use warnings;

use Data::MARC::Field008::MixedMaterial;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::MARC::Field008::MixedMaterial->new(
	'form_of_item' => 'r',
);
is($obj->raw, undef, 'Get raw (undef - default).');

# Test.
$obj = Data::MARC::Field008::MixedMaterial->new(
	'form_of_item' => 'r',
	'raw' => '     r           ',
);
is($obj->raw, '     r           ', 'Get raw (     r           ).');
