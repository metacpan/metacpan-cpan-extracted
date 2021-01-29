use strict;
use warnings;

use CSS::Struct::Output::Indent::ANSIColor;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($CSS::Struct::Output::Indent::ANSIColor::VERSION, 0.01, 'Version.');
