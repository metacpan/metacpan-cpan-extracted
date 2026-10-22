use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);
use POSIX qw(_exit);
use IO::Pipe;
use Fcntl qw(O_RDWR SEEK_SET);

use Data::Graph::Shared;

# Record a held mutex, then kill its owner without reaping it.
# Recovery must recognize the zombie and preserve committed data.

use File::Temp qw(tempdir);
my $dir = tempdir(CLEANUP => 1);
my $path = "$dir/graph";

{
    my $g = Data::Graph::Shared->new($path, 128, 512);
    my $seed_id = $g->add_node(1);

    my $pipe = IO::Pipe->new;
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        $pipe->writer;
        my $child = Data::Graph::Shared->new($path, 128, 512);
        my @ids = map { $child->add_node($_) } (2..20);
        sysopen my $file, $path, O_RDWR or _exit(2);
        sysseek($file, 72, SEEK_SET) == 72 or _exit(2);  # GraphHeader.mutex
        syswrite($file, pack('L', 0x80000000 | $$)) == 4 or _exit(2);
        close $file;
        print $pipe "ready\n";
        $pipe->close;
        sleep(60);
        _exit(0);
    }
    $pipe->reader;
    <$pipe> // die 'child did not record the held mutex';
    $pipe->close;

    kill 9, $pid;
    diag "child $pid killed";

    my $t0 = time;
    my $nid = $g->add_node(99);
    my $dt = time - $t0;
    waitpid $pid, 0;
    ok defined $nid, sprintf('add_node after child crash (%.2fs)', $dt);
    ok $dt < 5, sprintf('recovery within 5s (%.2fs)', $dt);
    ok $g->has_node($nid), 'new node present';
    ok $g->has_node($seed_id), 'seed node preserved';
    cmp_ok $g->node_count, '>=', 20, 'child nodes preserved';
}

unlink $path;
done_testing;
