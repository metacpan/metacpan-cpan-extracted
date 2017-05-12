# Pragmas.
use strict;
use warnings;

# Modules.
use Curses::UI::Time;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Curses::UI::Time::VERSION, 0.05, 'Version.');
