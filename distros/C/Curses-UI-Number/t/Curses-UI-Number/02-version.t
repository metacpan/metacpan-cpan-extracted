use strict;
use warnings;

use Curses::UI::Number;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Curses::UI::Number::VERSION, 0.07, 'Version.');
