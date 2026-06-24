use strict;
use warnings;

use Data::Metadata;
use Data::Metadata::KeyValue;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 7;
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
isa_ok($obj, 'Data::Metadata');

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
isa_ok($obj, 'Data::Metadata');

# Test.
eval {
	Data::Metadata->new;
};
is($EVAL_ERROR, "Parameter 'key_values' is required.\n",
	"Parameter 'key_values' is required.");
clean();

# Test.
eval {
	Data::Metadata->new(
		'id' => 'bad',
		'key_values' => [
			Data::Metadata::KeyValue->new(
				'id' => 7,
				'key' => 'text',
				'value' => 'This is text',
			),
		],
	);
};
is($EVAL_ERROR, "Parameter 'id' must be a positive natural number.\n",
	"Parameter 'id' must be a positive natural number (bad).");
clean();

# Test.
eval {
	Data::Metadata->new(
		'id' => 0,
		'key_values' => [
			Data::Metadata::KeyValue->new(
				'id' => 7,
				'key' => 'text',
				'value' => 'This is text',
			),
		],
	);
};
is($EVAL_ERROR, "Parameter 'id' must be a positive natural number.\n",
	"Parameter 'id' must be a positive natural number (0).");
clean();

# Test.
eval {
	Data::Metadata->new(
		'id' => 1.2,
		'key_values' => [
			Data::Metadata::KeyValue->new(
				'id' => 7,
				'key' => 'text',
				'value' => 'This is text',
			),
		],
	);
};
is($EVAL_ERROR, "Parameter 'id' must be a positive natural number.\n",
	"Parameter 'id' must be a positive natural number (1.2).");
clean();
