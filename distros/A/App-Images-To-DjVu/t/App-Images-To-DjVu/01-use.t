use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('App::Images::To::DjVu');
}

# Test.
require_ok('App::Images::To::DjVu');
