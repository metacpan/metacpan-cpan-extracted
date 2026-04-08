use strict;
use warnings;

use App::Bin::Search;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::Bin::Search::VERSION, 0.03, 'Version.');
