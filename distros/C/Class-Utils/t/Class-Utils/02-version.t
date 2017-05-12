# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Utils;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Class::Utils::VERSION, 0.07, 'Version.');
