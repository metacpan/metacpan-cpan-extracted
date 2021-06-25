use strict;
use warnings;

use English qw(-no_match_vars);
use CSS::Struct::Output::Structure;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
eval {
	CSS::Struct::Output::Structure->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", "Unknown parameter ''.");

# Test.
eval {
	CSS::Struct::Output::Structure->new('something' => 'value');
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	"Unknown parameter 'something'.");

# Test.
eval {
	CSS::Struct::Output::Structure->new('output_handler' => '');
};
is($EVAL_ERROR, 'Output handler is bad file handler.'."\n",
	'Output handler is bad file handler.');

# Test.
my $obj = CSS::Struct::Output::Structure->new;
isa_ok($obj, 'CSS::Struct::Output::Structure');
