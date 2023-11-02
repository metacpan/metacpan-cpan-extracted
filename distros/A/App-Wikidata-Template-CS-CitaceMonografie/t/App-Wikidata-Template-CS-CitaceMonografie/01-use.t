use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('App::Wikidata::Template::CS::CitaceMonografie');
}

# Test.
require_ok('App::Wikidata::Template::CS::CitaceMonografie');
