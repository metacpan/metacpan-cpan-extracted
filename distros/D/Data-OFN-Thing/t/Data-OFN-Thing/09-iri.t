use strict;
use warnings;

use Data::OFN::Thing;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Thing->new;
is($obj->iri, undef, 'Get IRI (undef - default).');

# Test.
$obj = Data::OFN::Thing->new(
	'iri' => 'https://example.com/aktivita',
);
is($obj->iri, 'https://example.com/aktivita',
	'Get IRI (https://example.com/aktivita).');
