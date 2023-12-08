use strict;
use warnings;

use Test::More 'tests' => 3;

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
my $ret = $obj->char;
is($ret, 'A', 'Get char (A).');

# Test.
$obj->char('B');
$ret = $obj->char;
is($ret, 'B', 'Get char after set (B).');
