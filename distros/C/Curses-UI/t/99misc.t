use strict;
use warnings;

use Test::More tests => 2;

$ENV{LINES} = 25;
$ENV{COLUMNS} = 80;

BEGIN { use_ok( "Curses::UI"); }

ok (!$Curses::UI::debug, "Debugging flag");
