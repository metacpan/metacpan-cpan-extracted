use strict;
use warnings;
use Test::Most;
use Gtk3;
use App::TimeTracker::Gtk3StatusIcon;

SKIP: {
    skip 'Gtk3->init_check failed, probably unable to open DISPLAY', 1 unless Gtk3->init_check;

    lives_ok {
        App::TimeTracker::Gtk3StatusIcon->init;
    } 'init seems to work';
}

done_testing();
