use strict;
use warnings;

use Business::UDC::Grammar;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Business::UDC::Grammar::VERSION, 0.02, 'Version.');
