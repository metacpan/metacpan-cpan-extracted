# Pragmas.
use strict;
use warnings;

# Modules.
use Acme::People::Happy;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Acme::People::Happy::VERSION, 0.03, 'Version.');
