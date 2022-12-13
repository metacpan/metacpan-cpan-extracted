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

# Add volume.
my $vol = $win->add(
        undef, 'Curses::UI::Volume',
        '-border' => 1,
        '-volume' => 0,
        '-title' => 'foo',
        '-width' => 10,
);

# Binding for quit.
$win->set_binding(\&exit, "\cQ", "\cC");

# Time.
$cui->set_timer(
        'timer',
        sub {
                my $act = $vol->volume;
                $act += 5;
                if ($act > 100) {
                        $act = 0;
                }
                $vol->volume($act);
                return;
        },
        1,
);

# Loop.
$cui->mainloop;

# Output like:
# ┌ foo ───┐
# │▊       │
# └────────┘