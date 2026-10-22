use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX qw(_exit WNOHANG);
use Time::HiRes qw(time usleep);
use Data::Heap::Shared;

my $dir = tempdir(CLEANUP => 1);

for my $locked (0, 1) {
    my $path = "$dir/$locked.heap";
    my $heap = Data::Heap::Shared->new($path, 4);
    open my $file, '+<:raw', $path or die $!;
    my $pid = fork // die $!;
    if (!$pid) {
        my @got = $heap->pop_wait;
        _exit(@got == 2 && $got[0] == 7 && $got[1] == 70 ? 0 : 1);
    }

    my $waiting = 0;
    my $deadline = time + 3;
    while (time < $deadline) {
        sysseek($file, 76, 0) // die $!;
        sysread($file, my $count, 4) == 4 or die $!;
        $waiting = unpack('L', $count) > 0;
        if ($waiting) { usleep 100_000; last }
        usleep 10_000;
    }
    ok $waiting, "consumer is asleep before producer crash (locked=$locked)";

    # Snapshot of a producer killed after publishing size, before FUTEX_WAKE.
    my $producer = fork // die $!;
    if (!$producer) {
        sysseek($file, 68, 0) // _exit(2);
        syswrite($file, pack('L', $locked ? 0x80000000 | $$ : 0)) == 4 or _exit(2);
        sysseek($file, 128, 0) // _exit(2);
        syswrite($file, pack('q q', 7, 70)) == 16 or _exit(2);
        sysseek($file, 64, 0) // _exit(2);
        syswrite($file, pack('L', 1)) == 4 or _exit(2);
        _exit(0);
    }
    waitpid $producer, 0;
    is $?, 0, 'crash snapshot published';

    my $status;
    $deadline = time + 6;
    while (time < $deadline) {
        if (waitpid($pid, WNOHANG) == $pid) { $status = $?; last }
        usleep 10_000;
    }
    if (!defined $status) { kill 'KILL', $pid; waitpid $pid, 0 }
    is $status, 0, "consumer retrieves entry without another push (locked=$locked)";
    close $file;
}

done_testing;
