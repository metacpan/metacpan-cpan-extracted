use strict;
use warnings;

use App::Tickit::Hello;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::Tickit::Hello::VERSION, 0.01, 'Version.');
