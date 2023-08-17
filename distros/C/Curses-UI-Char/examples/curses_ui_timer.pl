#!/usr/bin/env perl

use strict;
use warnings;

use Curses::UI;

# Object.
my $cui = Curses::UI->new(
        -color_support => 1,
);

# Main window.
my $win = $cui->add('window_id', 'Window');

# Add number.
my $char = $win->add(
        undef, 'Curses::UI::Char',
        '-border' => 1,
        '-char' => 'A',
);

# Binding for quit.
$win->set_binding(\&exit, "\cQ", "\cC");

# Time.
$cui->set_timer(
        'timer',
        sub {
                my $act = ord($char->char) - 65;
                $act += 1;
                if ($act > 25) {
                        $act = 0;
                }
                $char->char(chr($act + 65));

                return;
        },
        1,
);

# Loop.
$cui->mainloop;

# Output like:
# ┌──────┐
# │██████│
# │██  ██│
# │██  ██│
# │██  ██│
# │██████│
# └──────┘