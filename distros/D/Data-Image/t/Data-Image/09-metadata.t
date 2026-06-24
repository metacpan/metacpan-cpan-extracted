use strict;
use warnings;

use Data::Image;
use Data::Metadata;
use Data::Metadata::KeyValue;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Data::Image->new(
	'metadata' => Data::Metadata->new(
		'key_values' => [
			Data::Metadata::KeyValue->new(
				'key' => 'photographed_in',
				'value' => 'atelier',
			),
		],
	),
);
isa_ok($obj->metadata, 'Data::Metadata');
is($obj->metadata->key_values->[0]->key, 'photographed_in', 'Get first metadata key (photographed_in).');

# Test.
$obj = Data::Image->new;
is($obj->metadata, undef, 'Get metadata (undef - default).');
