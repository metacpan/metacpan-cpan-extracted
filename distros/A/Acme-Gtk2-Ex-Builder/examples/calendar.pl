#!/usr/bin/env perl

use 5.010;
use utf8;
use strict;
use warnings;
use autodie;
use Gtk2 '-init';
use Acme::Gtk2::Ex::Builder;

my $app = build {
    widget Window => contain {
        info id           => 'window';
        set  title        => 'Calendar Example';
        set  position     => 'center';
        on   delete_event => \&quit;
        widget VBox => contain {
            widget Calendar => contain {
                info id                          => 'cal';
                on   'day-selected-double-click' => \&cal_double_clicked;
            };
            widget Button => contain {
                set label   => 'Quit';
                on  clicked => \&quit;
            };
        };
    };
};

my $cal = $app->find('cal');
$cal->mark_day($_) for 1, 11, 21, 29;

$app->find('window')->show_all;
Gtk2->main;

sub quit {
    Gtk2->main_quit;
}

sub cal_double_clicked {
    my $self = shift;

    my ($year, $month, $day) = $self->get_date;
    say sprintf("%04d-%02d-%02d", $year, $month + 1, $day);
}
