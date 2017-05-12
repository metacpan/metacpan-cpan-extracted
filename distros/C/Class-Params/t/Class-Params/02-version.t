# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Params;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Class::Params::VERSION, 0.04, 'Version.');
