#!/usr/bin/perl
use warnings;
use strict;
use Curses::UI::POE;

#my $cui = new Curses::UI;
my $cui = new Curses::UI::POE;

my $win = $cui->add('window_id', 'Window');
my $listbox = $win->add ( 'mylistbox',
    'Listbox',
    -values => [1, 2, 3],
    -labels => {
        1 => 'One',
        2 => 'Two',
        3 => 'Three'
    },
    -radio => 1,
);
$win->focus();

# <CTRL+Q> : quit.
$cui->set_binding( sub{ exit }, "\cQ" );

$cui->mainloop();

