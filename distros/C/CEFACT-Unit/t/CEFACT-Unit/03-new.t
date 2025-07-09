use strict;
use warnings;

use CEFACT::Unit;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
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
