use strict;
use warnings;

use Check::Term;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Check::Term::VERSION, 0.01, 'Version.');
