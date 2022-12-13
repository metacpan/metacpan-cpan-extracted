use strict;
use warnings;

use Curses::UI::Volume;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Curses::UI::Volume::VERSION, 0.03, 'Version.');
