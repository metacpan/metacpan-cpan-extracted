use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($CSS::Struct::Output::Indent::VERSION, 0.03, 'Version.');
