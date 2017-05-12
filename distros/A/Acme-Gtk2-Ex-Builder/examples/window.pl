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
        info id               => 'window';
        set  position         => 'center';
        prop title            => 'Window Example';
        prop opacity          => 0.8;
        prop 'default-width'  => 640;
        prop 'default-height' => 480;
        on   delete_event     => \&quit;
    };
};

$app->find('window')->show_all;
Gtk2->main;

sub quit {
    Gtk2->main_quit;
}
