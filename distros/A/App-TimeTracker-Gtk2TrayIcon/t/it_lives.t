use strict;
use warnings;
use Test::Most;
use Gtk2;
use App::TimeTracker::Gtk2TrayIcon;

SKIP: {
    skip 'Gtk2->init_check failed, probably unable to open DISPLAY', 1 unless Gtk2->init_check;

    lives_ok {
        App::TimeTracker::Gtk2TrayIcon->init;
    } 'init seems to work';
}

done_testing();
