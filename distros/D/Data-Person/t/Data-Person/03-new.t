use strict;
use warnings;

use Data::Person;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Data::Person->new;
isa_ok($obj, 'Data::Person');

# Test.
$obj = Data::Person->new(
	'email' => 'skim@cpan.org',
	'id' => 1,
	'name' => decode_utf8('Michal Josef Špaček'),
	'sex' => 'male',
);
isa_ok($obj, 'Data::Person');

# Test.
eval {
	Data::Person->new(
		'id' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'id' must be a natural number.\n",
	"Parameter 'id' must be a natural number (bad).");
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
