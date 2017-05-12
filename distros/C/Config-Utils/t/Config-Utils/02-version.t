# Pragmas.
use strict;
use warnings;

# Modules.
use Config::Utils;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Config::Utils::VERSION, 0.06, 'Version.');
