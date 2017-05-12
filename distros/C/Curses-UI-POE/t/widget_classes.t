use strict;
use Test;

BEGIN { plan tests => 14 }

foreach my $class (qw(
    Curses::UI::Checkbox
    Curses::UI::Calendar
    Curses::UI::Label
    Curses::UI::Menubar
    Curses::UI::Progressbar
    Curses::UI::PasswordEntry
    Curses::UI::Buttonbox
    Curses::UI::Listbox
    Curses::UI::Popupmenu
    Curses::UI::TextEditor
    Curses::UI::TextEntry
    Curses::UI::TextViewer
    Curses::UI::Window
    Curses::UI::Radiobuttonbox )) {

    my $file = $class;
    $file =~ s|::|/|g;
    $file .= '.pm';

    require $file;
    ok(1);
}

