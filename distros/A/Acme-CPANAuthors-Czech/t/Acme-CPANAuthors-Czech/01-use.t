use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Acme::CPANAuthors::Czech');
}

# Test.
require_ok('Acme::CPANAuthors::Czech');
