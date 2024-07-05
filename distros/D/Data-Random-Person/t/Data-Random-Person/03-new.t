use strict;
use warnings;

use Data::Random::Person;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Data::Random::Person->new;
isa_ok($obj, 'Data::Random::Person');

# Test.
eval {
	Data::Random::Person->new(
		'domain' => '@bad',
	);
};
is($EVAL_ERROR, "Parameter 'domain' is not valid.\n",
	"Parameter 'domain' is not valid (\@bad).");
clean();

# Test.
eval {
	Data::Random::Person->new(
		'mode_id' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'mode_id' must be a bool (0/1).\n",
	"Parameter 'mode_id' must be a bool (0/1) (bad).");
clean();
