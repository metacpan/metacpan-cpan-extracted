use strict;
use warnings;

use Data::OFN::Common::Quantity;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Common::Quantity->new(
	'unit' => 'KGM',
	'value' => 10,
);
isa_ok($obj, 'Data::OFN::Common::Quantity');

# Test.
eval {
	Data::OFN::Common::Quantity->new(
		'value' => 10,
	);
};
is($EVAL_ERROR, "Parameter 'unit' is required.\n",
	"Parameter 'unit' is required.");
clean();

# Test.
eval {
	Data::OFN::Common::Quantity->new(
		'unit' => 'XXX',
		'value' => 10,
	);
};
is($EVAL_ERROR, "Parameter 'unit' must be a UN/CEFACT unit common code.\n",
	"Parameter 'unit' must be a UN/CEFACT unit common code. (XXX).");
clean();

# Test.
eval {
	Data::OFN::Common::Quantity->new(
		'unit' => 'KGM',
	);
};
is($EVAL_ERROR, "Parameter 'value' is required.\n",
	"Parameter 'value' is required.");
clean();
