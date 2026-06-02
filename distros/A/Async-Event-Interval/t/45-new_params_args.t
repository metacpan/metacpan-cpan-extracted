use warnings;
use strict;

use IPC::Shareable;
use Test::More;

my ($segs_before, $sems_before);
BEGIN {
    IPC::Shareable->testing_set('Async::Event::Interval');
    $segs_before = IPC::Shareable::seg_count();
    $sems_before = IPC::Shareable::sem_count();
}

use Async::Event::Interval;

warn "Segs Before: $segs_before\n" if $ENV{PRINT_SEGS};
warn "Sems Before: $sems_before\n" if $ENV{PRINT_SEGS};

my @params = qw(1 2 3);

my $event = Async::Event::Interval->new(
    0,
    \&callback_multi,
    @params
);

$event->start;

sleep 1;

sub callback_multi {
    is $_[0], 1, "first param of array ok: 1";
    is $_[1], 2, "first param of array ok: 2";
    is $_[2], 3, "first param of array ok: 3";
    done_testing();
}