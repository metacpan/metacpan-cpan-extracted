# Pragmas.
use strict;
use warnings;

# Modules.
use Curses::UI::Volume;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Curses::UI::Volume::VERSION, 0.02, 'Version.');
