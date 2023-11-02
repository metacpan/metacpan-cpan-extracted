use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('App::Wikidata::Template::CS::CitaceMonografie', 'App::Wikidata::Template::CS::CitaceMonografie is covered.');
