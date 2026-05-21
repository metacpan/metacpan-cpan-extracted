use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('App::Lorem::Tickit::TextWidget');
}

# Test.
require_ok('App::Lorem::Tickit::TextWidget');
