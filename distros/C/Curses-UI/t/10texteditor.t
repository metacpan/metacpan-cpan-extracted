# -*- perl -*-
use Test::More tests => 5;
use FindBin;
use lib "$FindBin::RealBin/fakelib";
require ("$FindBin::RealBin/lorem.pl");

$ENV{LINES} = 25;
$ENV{COLUMNS} = 80;

BEGIN { use_ok( "Curses::UI"); }

close STDIN or warn $!;

my $cui = new Curses::UI("-clear_on_exit" => 0,
		         "-mouse_support" => 1);

$cui->leave_curses();

isa_ok($cui, "Curses::UI");

my $mainw = $cui->add("testw","Window");

isa_ok($mainw, "Curses::UI::Window");

my $wid = $mainw->add("testwidget","TextEditor");

isa_ok($wid, "Curses::UI::TextEditor");

$wid->text($lorem);

ok($wid->get() eq $lorem, "get and set");


