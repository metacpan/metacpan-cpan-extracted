use strict;
use warnings;

use App::Stow::Check;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::Stow::Check::VERSION, 0.01, 'Version.');
