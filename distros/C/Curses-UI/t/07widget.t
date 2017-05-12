# -*- perl -*-
use strict;
use Test::More tests => 6;
use FindBin;
use lib "$FindBin::RealBin/fakelib";

$ENV{LINES} = 25;
$ENV{COLUMNS} = 80;

BEGIN { use_ok( "Curses::UI"); }

my $cui = new Curses::UI("-clear_on_exit" => 0);

$cui->leave_curses();

isa_ok($cui, "Curses::UI");

my $mainw = $cui->add("testw","Window");

isa_ok($mainw, "Curses::UI::Window");

my $wid = $mainw->add("testwidget","Widget");

isa_ok($wid, "Curses::UI::Widget");

$wid->set_routine("foo", "bar");

$wid->set_binding("foo", sub { print 1; } );

ok($wid->parentwindow eq $mainw, "parentwindow()");
ok($wid->in_topwindow, "in_topwindow()");



