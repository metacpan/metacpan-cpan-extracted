use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('App::Wikidata::Print');
}

# Test.
require_ok('App::Wikidata::Print');
