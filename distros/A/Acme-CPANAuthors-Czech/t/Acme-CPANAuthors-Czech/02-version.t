use strict;
use warnings;

use Acme::CPANAuthors::Czech;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Acme::CPANAuthors::Czech::VERSION, 0.25, 'Version.');
