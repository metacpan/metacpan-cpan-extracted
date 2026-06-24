use strict;
use warnings;

use Data::Metadata;
use Data::Metadata::KeyValue;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Metadata->new(
	'id' => 7,
	'key_values' => [
		Data::Metadata::KeyValue->new(
			'id' => 7,
			'key' => 'text',
			'value' => 'This is text',
		),
	],
);
is($obj->id, 7, 'Get id (7).');

# Test.
$obj = Data::Metadata->new(
	'key_values' => [
		Data::Metadata::KeyValue->new(
			'id' => 7,
			'key' => 'text',
			'value' => 'This is text',
		),
	],
);
is($obj->id, undef, 'Get id (undef - default).');
