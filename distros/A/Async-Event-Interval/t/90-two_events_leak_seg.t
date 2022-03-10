use warnings;
use strict;

my $segs_begin;

use Data::Dumper;
use IPC::Shareable;
use Test::More;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a legit CI platform...";
    }
    warn "Segs Before Async::Event::Interval: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};
    $segs_begin = IPC::Shareable::ipcs();
}

use Async::Event::Interval;
use Data::Dumper;

my $segs_before = IPC::Shareable::ipcs();

{
    my $segs_before_ipc_create = IPC::Shareable::ipcs();
    is
        $segs_before_ipc_create,
        $segs_begin + 1,
        "Proper number of segs before IPC create, and after Async::Event::Interval";

    tie my %shared_data, 'IPC::Shareable', {
        key     => 'fork rand dup keys',
        create  => 1,
        destroy => 1
    };

    my $segs_after_ipc_create = IPC::Shareable::ipcs();
    is
        $segs_after_ipc_create,
        $segs_begin + 2,
        "Proper number of segs after IPC create";

    my $event_one = Async::Event::Interval->new(0, sub {$shared_data{$$}{called}++});
    my $event_two = Async::Event::Interval->new(0, sub {$shared_data{$$}{called}++});

    $event_one->start;
    $event_two->start;

    sleep 1;

    $event_one->stop;
    $event_two->stop;

    my $one_pid = $event_one->pid;
    my $two_pid = $event_two->pid;

    is exists $shared_data{$one_pid}{called}, 1, "Event one got a rand shm key ok";
    is exists $shared_data{$two_pid}{called}, 1, "Adding srand() ensures _shm_key_rand() gives out rand key in fork()";

    my $segs_before_ipc_cleaned = IPC::Shareable::ipcs();
    is
        $segs_before_ipc_cleaned,
        $segs_begin + 6,
        "1 seg for AEI, 1 seg for IPC, 2 segs for events, 2 entries for adds by each event to IPC";

    IPC::Shareable::clean_up_all;

    my $segs_after_ipc_cleaned = IPC::Shareable::ipcs();
    is
        $segs_after_ipc_cleaned,
        $segs_begin + 3,
        "Proper number of segs after IPC cleanup, before AEI destroy on two events";
}

my $segs_destroy = IPC::Shareable::ipcs();
is
    $segs_destroy,
    $segs_begin + 3,
    "All %event segs cleaned up after Async::Event::Interval DESTROY";

Async::Event::Interval::_end;
IPC::Shareable::_end;

my $segs_after = IPC::Shareable::ipcs();
is
    $segs_after,
    $segs_begin,
    "%event seg cleaned up after Async::Event::Interval END";

warn "Segs After: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};

done_testing();