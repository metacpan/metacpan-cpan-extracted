# -*- perl -*-
use Test::More tests => 10;
use strict;
use FindBin;
use lib "$FindBin::RealBin/fakelib";

$ENV{LINES} = 25;
$ENV{COLUMNS} = 80;

BEGIN { use_ok( "Curses::UI");
	require ("$FindBin::RealBin/lorem.pl"); }
my $c = 0;
my $counter = sub { return $c++ };

my $cui = new Curses::UI("-clear_on_exit" => 0);

$cui->leave_curses();

isa_ok($cui, "Curses::UI");

my $mainw = $cui->add("testw","Window");

isa_ok($mainw, "Curses::UI::Window");

my $wid = $mainw->add("testwidget","Listbox");

$wid->onChange($counter);

$wid->focus;

isa_ok($wid, "Curses::UI::Listbox");

$wid->values( \@lorem );

ok(! defined $wid->get(), "get()");

$wid->set_selection( 1, 4, 7, 99, 5 );

ok($wid->get() eq "consectetur","set_selection() get()");

$wid->set_selection( 3 );

ok($wid->get() eq "sit","set_selection() get()");

ok($wid->get_active_value() eq "Lorem", "get_active_value()");

$wid->clear_selection();

ok(! defined $wid->get(), "get()");

ok( &$counter == 5, "onChange event");

