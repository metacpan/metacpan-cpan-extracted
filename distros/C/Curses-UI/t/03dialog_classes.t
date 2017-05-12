# -*- perl -*-
use strict;
use Test;

BEGIN { plan tests => 8 }

foreach my $class (qw(
    Curses::UI::Dialog::Basic
    Curses::UI::Dialog::Filebrowser
    Curses::UI::Dialog::Error
    Curses::UI::Dialog::Status
    Curses::UI::Dialog::Calendar
    Curses::UI::Dialog::Dirbrowser
    Curses::UI::Dialog::Progress 
    Curses::UI::Dialog::Question
		      )) {

    my $file = $class;
    $file =~ s|::|/|g;
    $file .= '.pm';

    require $file;
    ok(1);
}

