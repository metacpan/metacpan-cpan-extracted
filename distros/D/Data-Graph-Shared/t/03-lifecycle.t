use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Data::Graph::Shared;

# memfd + new_from_fd round-trip
{
    my $g = Data::Graph::Shared->new_memfd("lifecycle_test", 10, 20);
    ok $g, 'new_memfd created';
    ok $g->memfd >= 0, 'memfd returns non-negative fd';
    ok !defined $g->path, 'anon/memfd has no path';

    my $a = $g->add_node(42);
    my $b = $g->add_node(99);
    $g->add_edge($a, $b, 7);

    # Reopen via fd
    my $fd = POSIX::dup($g->memfd);
    ok $fd >= 0, 'dup fd ok';
    my $g2 = Data::Graph::Shared->new_from_fd($fd);
    is $g2->node_count, 2, 'new_from_fd sees existing nodes';
    is $g2->edge_count, 1, 'new_from_fd sees existing edge';
    POSIX::close($fd);
}

# memfd + fork inheritance
{
    my $g = Data::Graph::Shared->new_memfd("fork_test", 8, 16);
    $g->add_node(100);
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        $g->add_node(200);
        _exit(0);
    }
    waitpid $pid, 0;
    is $g->node_count, 2, 'fork-child node visible';
}

# sync() on file-backed
{
    use File::Temp qw(tmpnam);
    my $path = tmpnam() . '.graph';
    my $g = Data::Graph::Shared->new($path, 4, 4);
    $g->add_node(1);
    eval { $g->sync };
    ok !$@, 'sync on file-backed does not croak';
    $g->unlink;
    ok !-e $path, 'unlink removed file';
}

# eventfd lazy-create + notify/consume
{
    my $g = Data::Graph::Shared->new(undef, 4, 4);
    is $g->fileno, -1, 'no eventfd initially';
    my $fd = $g->eventfd;
    ok $fd >= 0, 'eventfd lazy-created';
    is $g->fileno, $fd, 'fileno matches';
    $g->notify;
    $g->notify;
    is $g->eventfd_consume, 2, 'consume sees accumulated count';
}

done_testing;
