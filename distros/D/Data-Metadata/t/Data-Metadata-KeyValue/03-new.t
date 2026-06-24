use strict;
use warnings;

use Data::Metadata::KeyValue;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $obj = Data::Metadata::KeyValue->new(
	'id' => 7,
	'key' => 'text',
	'value' => 'This is text',
);
isa_ok($obj, 'Data::Metadata::KeyValue');

# Test.
$obj = Data::Metadata::KeyValue->new(
	'key' => 'text',
);
isa_ok($obj, 'Data::Metadata::KeyValue');

# Test.
eval {
	Data::Metadata::KeyValue->new;
};
is($EVAL_ERROR, "Parameter 'key' is required.\n",
	"Parameter 'key' is required.");
clean();

# Test.
eval {
	Data::Metadata::KeyValue->new(
		'id' => 'bad',
		'key' => 'text',
	);
};
is($EVAL_ERROR, "Parameter 'id' must be a positive natural number.\n",
	"Parameter '%s' must be a positive natural number (bad).");
clean();

# Test.
eval {
	Data::Metadata::KeyValue->new(
		'id' => 0,
		'key' => 'text',
	);
};
is($EVAL_ERROR, "Parameter 'id' must be a positive natural number.\n",
	"Parameter '%s' must be a positive natural number (0).");
clean();

# Test.
eval {
	Data::Metadata::KeyValue->new(
		'id' => 1.1,
		'key' => 'text',
	);
};
is($EVAL_ERROR, "Parameter 'id' must be a positive natural number.\n",
	"Parameter '%s' must be a positive natural number (1.1).");
clean();
