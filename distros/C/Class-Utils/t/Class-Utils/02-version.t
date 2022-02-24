use strict;
use warnings;

use Class::Utils;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Class::Utils::VERSION, 0.12, 'Version.');
