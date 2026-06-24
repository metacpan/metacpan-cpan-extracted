use strict;
use warnings;

use Data::Metadata;
use Data::Metadata::KeyValue;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Metadata->new(
	'key_values' => [
		Data::Metadata::KeyValue->new(
			'id' => 7,
			'key' => 'text',
			'value' => 'This is text',
		),
	],
);
my @ret = @{$obj->key_values};
isa_ok($ret[0], 'Data::Metadata::KeyValue');
is(scalar @ret, 1, 'Get count of key/value items (1).');
