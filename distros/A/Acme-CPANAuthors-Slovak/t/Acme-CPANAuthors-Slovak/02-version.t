use strict;
use warnings;

use Acme::CPANAuthors::Slovak;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Acme::CPANAuthors::Slovak::VERSION, 0.27, 'Version.');
