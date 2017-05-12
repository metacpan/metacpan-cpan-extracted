use Test::More tests => 8;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::RealBin/fakelib";

$ENV{LINES} = 25;
$ENV{COLUMNS} = 80;

BEGIN { use_ok( "Curses::UI");
        use_ok( "Curses::UI::Color");}

my $cui = new Curses::UI("-clear_on_exit" => 0);

$cui->leave_curses();

isa_ok($cui, "Curses::UI");

$cui->userdata("foo bar baz");

ok($cui->userdata eq "foo bar baz", "userdata");

ok($cui->clear_on_exit() == 0, "clear_on_exit()");
$cui->clear_on_exit(1);
ok($cui->clear_on_exit() == 1, "clear_on_exit()");
$cui->clear_on_exit(0);
my $color = new Curses::UI::Color;
isa_ok($color, "Curses::UI::Color");

$cui->set_color($color);

ok($cui->color() eq $color, "set_color");
