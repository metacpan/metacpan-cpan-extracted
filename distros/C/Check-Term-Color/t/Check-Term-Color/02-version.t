use strict;
use warnings;

use Check::Term::Color;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Check::Term::Color::VERSION, 0.01, 'Version.');
