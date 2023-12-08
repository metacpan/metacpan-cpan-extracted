use strict;
use warnings;

use Test::More 'tests' => 2;

use FindBin;
use lib "$FindBin::RealBin/../data/fakelib";

BEGIN { use_ok "Curses::UI"; }

$ENV{LINES} = 25;
$ENV{COLUMNS} = 80;

# Test.
my $cui = Curses::UI->new('-clear_on_exit' => 0);
$cui->leave_curses;
my $main_window = $cui->add('test_windows', 'Window');
my $obj = $main_window->add('test_widget', 'Char', '-char', 'A');
isa_ok($obj, 'Curses::UI::Char');
