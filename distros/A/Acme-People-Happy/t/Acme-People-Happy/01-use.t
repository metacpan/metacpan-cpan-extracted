# Pragmas.
use strict;
use warnings;

# Modules.
use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Acme::People::Happy');
}

# Test.
require_ok('Acme::People::Happy');
