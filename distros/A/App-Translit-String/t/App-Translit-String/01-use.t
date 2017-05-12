# Pragmas.
use strict;
use warnings;

# Modules.
use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('App::Translit::String');
}

# Test.
require_ok('App::Translit::String');
