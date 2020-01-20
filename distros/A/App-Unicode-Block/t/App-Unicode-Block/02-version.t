use strict;
use warnings;

use App::Unicode::Block;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::Unicode::Block::VERSION, 0.01, 'Version.');
