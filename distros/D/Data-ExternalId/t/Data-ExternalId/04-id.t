use strict;
use warnings;

use Data::ExternalId;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::ExternalId->new(
	'key' => 'VIAF',
	'value' => '265219579',
);
is($obj->id, undef, 'Get id (undef - default).');

# Test.
$obj = Data::ExternalId->new(
	'id' => 7,
	'key' => 'VIAF',
	'value' => '265219579',
);
is($obj->id, 7, 'Get id (7).');
