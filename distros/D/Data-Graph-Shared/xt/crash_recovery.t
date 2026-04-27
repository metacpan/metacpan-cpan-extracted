use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);
use POSIX qw(_exit);
use IO::Pipe;

use Data::Graph::Shared;

# ============================================================
# Graph: writer crashes while holding the mutex.
# Parent opens the same file-backed graph and expects recovery
# within ~2s (LOCK_TIMEOUT_SEC).
# ============================================================

use File::Temp qw(tmpnam);
my $path = tmpnam() . ".$$";

{
    my $g = Data::Graph::Shared->new($path, 128, 512);
    my $seed_id = $g->add_node(1);

    my $pipe = IO::Pipe->new;
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        $pipe->writer;
        my $child = Data::Graph::Shared->new($path, 128, 512);
        my @ids = map { $child->add_node($_) } (2..20);
        print $pipe "ready\n";
        $pipe->close;
        sleep(60);
        _exit(0);
    }
    $pipe->reader;
    <$pipe>;
    $pipe->close;

    kill 9, $pid;
    waitpid $pid, 0;
    diag "child $pid killed";

    my $t0 = time;
    my $nid = $g->add_node(99);
    my $dt = time - $t0;
    ok defined $nid, sprintf('add_node after child crash (%.2fs)', $dt);
    ok $dt < 5, sprintf('recovery within 5s (%.2fs)', $dt);
    ok $g->has_node($nid), 'new node present';
    ok $g->has_node($seed_id), 'seed node preserved';
    cmp_ok $g->node_count, '>=', 20, 'child nodes preserved';
}

unlink $path;
done_testing;
