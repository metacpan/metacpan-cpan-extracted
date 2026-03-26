use strict;
use warnings;

use Business::UDC::Parser;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Business::UDC::Parser::VERSION, 0.02, 'Version.');
