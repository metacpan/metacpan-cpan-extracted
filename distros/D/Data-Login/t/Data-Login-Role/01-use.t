use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Data::Login::Role');
}

# Test.
require_ok('Data::Login::Role');
