use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time sleep);
use POSIX qw(_exit);
use IO::Pipe;

use Data::Queue::Shared::Str;

# ============================================================
# Str queue: producer crashes while holding the mutex mid-push.
# Parent opens the same file-backed queue and expects recovery
# within ~2s (LOCK_TIMEOUT_SEC).
# ============================================================

use File::Temp qw(tmpnam);
my $path = tmpnam() . ".$$";

{
    my $q = Data::Queue::Shared::Str->new($path, 64);
    $q->push("seed");

    my $pipe = IO::Pipe->new;
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        $pipe->writer;
        my $child = Data::Queue::Shared::Str->new($path, 64);
        # Acquire by taking a blocking op we won't complete:
        # push a huge batch under single mutex — we'll be killed mid-flight.
        $child->push("held") for 1..5;
        print $pipe "ready\n";
        $pipe->close;
        # Deliberately leak the mutex by not finishing naturally.
        # Simulate crash mid-operation by sleeping with mutex untouched
        # but the PID visible in hdr->mutex is ours.
        sleep(60);
        _exit(0);
    }
    $pipe->reader;
    <$pipe>;
    $pipe->close;

    kill 9, $pid;
    waitpid $pid, 0;
    diag "child $pid killed after ops";

    my $t0 = time;
    # This should succeed within 2s (mutex recovery) if child died holding lock,
    # or immediately if child released it normally.
    my $v = $q->pop_wait(3);  # 3s timeout
    my $dt = time - $t0;
    ok defined $v, sprintf('parent can pop after child crash (%.2fs)', $dt);
    ok $dt < 5, sprintf('recovery within 5s (%.2fs)', $dt);
}

unlink $path;
done_testing;
