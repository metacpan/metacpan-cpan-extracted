# Pragmas.
use strict;
use warnings;

# Modules.
use App::Pod::Example;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::Pod::Example::VERSION, 0.16, 'Version.');
