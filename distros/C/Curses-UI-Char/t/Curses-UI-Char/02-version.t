use strict;
use warnings;

use Curses::UI::Char;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Curses::UI::Char::VERSION, 0.02, 'Version.');
