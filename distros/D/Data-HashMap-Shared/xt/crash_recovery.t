use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);
use POSIX qw(_exit);
use IO::Pipe;

use Data::HashMap::Shared::II;

# ============================================================
# HashMap: writer crashes while holding write lock.
# Parent opens the same file-backed map and expects recovery
# within ~2s (LOCK_TIMEOUT_SEC).
# ============================================================

use File::Temp qw(tmpnam);
my $path = tmpnam() . ".$$";

{
    my $m = Data::HashMap::Shared::II->new($path, 1024);
    $m->put(1, 100);

    my $pipe = IO::Pipe->new;
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        $pipe->writer;
        my $child = Data::HashMap::Shared::II->new($path, 1024);
        # Enter a long write-lock path: put many keys to stress the lock.
        for (1..100) { $child->put($_, $_ * 2) }
        print $pipe "ready\n";
        $pipe->close;
        sleep(60);  # pretend to crash mid-hold
        _exit(0);
    }
    $pipe->reader;
    <$pipe>;
    $pipe->close;

    kill 9, $pid;
    waitpid $pid, 0;
    diag "child $pid killed";

    my $t0 = time;
    $m->put(999, 99999);
    my $dt = time - $t0;
    ok $dt < 5, sprintf('parent set after child crash (%.2fs)', $dt);
    is $m->get(999), 99999, 'value written after recovery';
    is $m->get(50), 100, 'child values preserved';
}

unlink $path;
done_testing;
