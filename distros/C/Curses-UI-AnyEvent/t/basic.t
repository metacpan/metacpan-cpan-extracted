use strict;
use Test::More tests => 3;
use FindBin;
use lib "$FindBin::RealBin/fakelib";

$ENV{LINES} = 25;
$ENV{COLUMNS} = 80;

BEGIN { use_ok( "Curses::UI::AnyEvent"); }

my $cui = Curses::UI::AnyEvent->new("-clear_on_exit" => 0);
$cui->leave_curses();

my $watcher = AE::timer 0.1, 0, sub {
    ok(1, 'timer triggered');
    $cui->mainloopExit();
};

$cui->mainloop();

ok(1, 'exited');
