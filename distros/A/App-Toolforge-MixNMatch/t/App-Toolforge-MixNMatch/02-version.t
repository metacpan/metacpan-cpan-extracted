use strict;
use warnings;

use App::Toolforge::MixNMatch;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::Toolforge::MixNMatch::VERSION, 0.05, 'Version.');
