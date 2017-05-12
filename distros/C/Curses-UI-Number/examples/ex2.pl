#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Curses::UI;

# Object.
my $cui = Curses::UI->new(
        -color_support => 1,
);

# Main window.
my $win = $cui->add('window_id', 'Window');

# Add number.
my $num = $win->add(
        undef, 'Curses::UI::Number',
        '-border' => 1,
        '-num' => 0,
);

# Binding for quit.
$win->set_binding(\&exit, "\cQ", "\cC");

# Time.
$cui->set_timer(
        'timer',
        sub {
                my $act = $num->num;
                $act += 1;
                if ($act > 9) {
                        $act = 0;
                }
                $num->num($act);
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
# │██████│
# │██  ██│
# │██████│
# └──────┘