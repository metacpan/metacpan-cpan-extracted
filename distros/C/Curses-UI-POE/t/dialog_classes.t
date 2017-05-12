use strict;
use Test;

BEGIN { plan tests => 6 }

foreach my $class (qw(
    Curses::UI::Dialog::Basic
    Curses::UI::Dialog::Filebrowser
    Curses::UI::Dialog::Error
    Curses::UI::Dialog::Status
    Curses::UI::Dialog::Calendar
    Curses::UI::Dialog::Progress )) {

    my $file = $class;
    $file =~ s|::|/|g;
    $file .= '.pm';

    require $file;
    ok(1);
}

