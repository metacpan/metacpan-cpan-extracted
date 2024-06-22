use strict;
use warnings;

use App::Wikidata::Print;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::Wikidata::Print::VERSION, 0.04, 'Version.');
