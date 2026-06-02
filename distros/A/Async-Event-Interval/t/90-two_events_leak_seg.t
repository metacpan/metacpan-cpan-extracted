use warnings;
use strict;

use IPC::Shareable;
use Test::More;

my ($segs_begin, $sems_begin);
BEGIN {
    IPC::Shareable->testing_set('Async::Event::Interval');
    $segs_begin = IPC::Shareable::seg_count();
    $sems_begin = IPC::Shareable::sem_count();
}

use Async::Event::Interval;

warn "Segs Before: $segs_begin\n" if $ENV{PRINT_SEGS};
warn "Sems Before: $sems_begin\n" if $ENV{PRINT_SEGS};

{
    my $segs_before_ipc_create = IPC::Shareable::seg_count();

    is
        $segs_before_ipc_create,
        $segs_begin + 1,
        "Proper number of segs before IPC create, and after Async::Event::Interval";

    tie my %shared_data, 'IPC::Shareable', {
        key     => 'fork rand dup keys',
        create  => 1,
        destroy => 1
    };

    my $segs_after_ipc_create = IPC::Shareable::seg_count();

    is
        $segs_after_ipc_create,
        $segs_begin + 2,
        "Proper number of segs after IPC create";

    my $event_one = Async::Event::Interval->new(0, sub {$shared_data{$$}++});
    my $event_two = Async::Event::Interval->new(0, sub {$shared_data{$$}++});

    $event_one->start;
    $event_two->start;

    sleep 1;

    $event_one->stop;
    $event_two->stop;

    my $one_pid = $event_one->pid;
    my $two_pid = $event_two->pid;

    ok exists $shared_data{$one_pid}, "Event one got a rand shm key ok";
    ok exists $shared_data{$two_pid}, "Adding srand() ensures _shm_key_rand() gives out rand key in fork()";

    my $segs_before_ipc_cleaned = IPC::Shareable::seg_count();

    is
        $segs_before_ipc_cleaned,
        $segs_begin + 4,
        "1 seg for AEI, 1 seg for IPC, 2 segs for events";

    IPC::Shareable::clean_up_all;

    my $segs_after_ipc_cleaned = IPC::Shareable::seg_count();

    is
        $segs_after_ipc_cleaned,
        $segs_begin + 3,
        "Proper number of segs after IPC cleanup, before AEI destroy on two events";
}

my $segs_destroy = IPC::Shareable::seg_count();

# IPC::Shareable 1.14 added _remove_child() which is invoked by STORE,
# DELETE, and CLEAR. When AEI's DESTROY does `delete $events{$id}` for
# each event going out of scope, the per-event child segment is now
# proactively removed (it used to leak). Only the protected %events
# parent remains here.

is
    $segs_destroy,
    $segs_begin + 1,
    "Per-event child segs are removed when each event DESTROYs; only the protected %event parent remains";

Async::Event::Interval::_end;
IPC::Shareable::_end;

my $segs_after = IPC::Shareable::seg_count();
my $sems_after = IPC::Shareable::sem_count();
warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};
warn "Sems After: $sems_after\n" if $ENV{PRINT_SEGS};

is
    $segs_after,
    $segs_begin,
    "%event seg cleaned up after Async::Event::Interval END";

is $sems_after, $sems_begin, "All semaphore sets cleaned up ok";

done_testing();