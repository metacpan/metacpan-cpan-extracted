use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('App::Lorem::Tickit::Widget');
}

# Test.
require_ok('App::Lorem::Tickit::Widget');
