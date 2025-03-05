use strict;
use warnings;

use Data::ExternalId;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = Data::ExternalId->new(
	'key' => 'VIAF',
	'value' => '265219579',
);
isa_ok($obj, 'Data::ExternalId');

# Test.
$obj = Data::ExternalId->new(
	'id' => 7,
	'key' => 'VIAF',
	'value' => '265219579',
);
isa_ok($obj, 'Data::ExternalId');

# Test.
eval {
	Data::ExternalId->new(
		'id' => 'bad',
		'key' => 'VIAF',
		'value' => '265219579',
	);
};
is($EVAL_ERROR, "Parameter 'id' must be a natural number.\n",
	"Parameter 'id' must be a natural number (bad).");
clean();

# Test.
eval {
	Data::ExternalId->new(
		'value' => '265219579',
	);
};
is($EVAL_ERROR, "Parameter 'key' is required.\n",
	"Parameter 'key' is required (not exists).");
clean();

# Test.
eval {
	Data::ExternalId->new(
		'key' => 'VIAF',
	);
};
is($EVAL_ERROR, "Parameter 'value' is required.\n",
	"Parameter 'value' is required (not exists).");
clean();
