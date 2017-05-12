# Pragmas.
use strict;
use warnings;

# Modules.
use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Config::Dot::Array');
}

# Test.
require_ok('Config::Dot::Array');
