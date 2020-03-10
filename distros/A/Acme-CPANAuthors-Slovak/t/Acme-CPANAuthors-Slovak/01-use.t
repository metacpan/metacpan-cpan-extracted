use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Acme::CPANAuthors::Slovak');
}

# Test.
require_ok('Acme::CPANAuthors::Slovak');
