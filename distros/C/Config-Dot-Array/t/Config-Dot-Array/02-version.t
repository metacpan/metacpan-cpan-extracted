# Pragmas.
use strict;
use warnings;

# Modules.
use Config::Dot::Array;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Config::Dot::Array::VERSION, 0.05, 'Version.');
