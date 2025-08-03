use strict;
use warnings;

use Data::ExternalId;
use Data::Person;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 7;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Data::Person->new;
isa_ok($obj, 'Data::Person');

# Test.
$obj = Data::Person->new(
	'email' => 'skim@cpan.org',
	'external_ids' => [
		Data::ExternalId->new(
			'key' => 'Wikidata',
			'value' => 'Q27954834',
		),
	],
	'id' => 1,
	'name' => decode_utf8('Michal Josef Špaček'),
	'sex' => 'male',
);
isa_ok($obj, 'Data::Person');

# Test.
eval {
	Data::Person->new(
		'external_ids' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'external_ids' must be a array.\n",
	"Parameter 'external_ids' must be a array (bad).");
clean;

# Test.
eval {
	Data::Person->new(
		'external_ids' => ['bad'],
	);
};
is($EVAL_ERROR, "Parameter 'external_ids' with array must contain 'Data::ExternalId' objects.\n",
	"Parameter 'external_ids' with array must contain 'Data::ExternalId' objects (bad).");
clean;

# Test.
eval {
	Data::Person->new(
		'id' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'id' must be a positive natural number.\n",
	"Parameter 'id' must be a positive natural number (bad).");
clean();

# Test.
eval {
	Data::Person->new(
		'name' => 'x' x 300,
	);
};
is($EVAL_ERROR, "Parameter 'name' has length greater than '255'.\n",
	"Parameter 'name' has length greater than '255'.");
clean();
