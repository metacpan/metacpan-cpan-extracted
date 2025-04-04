use strict;
use warnings;

use Data::ExternalId;
use Data::Person;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Person->new;
is_deeply(
	$obj->external_ids,
	[],
	'Get external ids ([] - default).',
);

# Test.
$obj = Data::Person->new(
	'external_ids' => [
		Data::ExternalId->new(
			'key' => 'Wikidata',
			'value' => 'Q27954834',
		),
	],
);
isa_ok($obj->external_ids->[0], 'Data::ExternalId');
