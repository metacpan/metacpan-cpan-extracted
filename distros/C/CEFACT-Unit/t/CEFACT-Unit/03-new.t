use strict;
use warnings;

use CEFACT::Unit;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = CEFACT::Unit->new;
isa_ok($obj, 'CEFACT::Unit');

# Test.
eval {
	CEFACT::Unit->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n",
	"Unknown parameter ''.");
clean();

# Test.
eval {
	CEFACT::Unit->new(
		'units' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'units' must be a array.\n",
	"Parameter 'units' must be a array (bad).");
clean();

# Test.
eval {
	CEFACT::Unit->new(
		'units' => ['bad'],
	);
};
is($EVAL_ERROR, "Parameter 'units' with array must contain 'Data::CEFACT::Unit' objects.\n",
	"Parameter 'units' with array must contain 'Data::CEFACT::Unit' objects (bad).");
clean();
