# Pragmas.
use strict;
use warnings;

# Modules.
use App::Translit::String;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::Translit::String::VERSION, 0.04, 'Version.');
