use strict;
use warnings;

use App::Wikidata::Template::CS::CitaceMonografie;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::Wikidata::Template::CS::CitaceMonografie::VERSION, 0.05, 'Version.');
