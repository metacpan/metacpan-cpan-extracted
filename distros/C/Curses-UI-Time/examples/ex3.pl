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

# Add time.
my $time = $win->add(
        undef, 'Curses::UI::Time',
        '-border' => 1,
        '-date' => 1,
        '-second' => 1,
        '-time' => time,
);

# Binding for quit.
$win->set_binding(\&exit, "\cQ", "\cC");

# Timer.
$cui->set_timer(
        'timer',
        sub {
                $time->time(time);
                $cui->draw(1);
                return;
        },
        1,
);

# Loop.
$cui->mainloop;

# Output like:
# ┌────────────────────────────────────────────────────┐
# │    ██     ██      ██████ ██████      ██  ██ ██████ │
# │    ██     ██  ██  ██  ██ ██  ██  ██  ██  ██ ██  ██ │
# │    ██     ██      ██  ██ ██  ██      ██████ ██  ██ │
# │    ██     ██  ██  ██  ██ ██  ██  ██      ██ ██  ██ │
# │    ██     ██      ██████ ██████          ██ ██████ │
# │                                                    │
# │                      2014-05-24                    │
# └────────────────────────────────────────────────────┘