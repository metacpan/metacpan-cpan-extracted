#!/usr/bin/env perl
# Cross-process: parent builds the structure via memfd, child opens the same fd,
# both mutate the one shared mapping.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::DisjointSet::Shared;
$| = 1;

# A "friendship" graph over 100 people (0 .. 99): unioning two people puts them
# in the same connected component. The parent records a few friendships, hands
# the shared memfd to a forked child that adds more -- including one edge that
# bridges two of the parent's groups -- and the parent then sees the merged
# partition. One shared union-find, no coordination.

my $d  = Data::DisjointSet::Shared->new_memfd('dsu-demo', 100);
my $fd = $d->memfd;

# Parent: two separate friend groups -- {0,1,2,3} and {10,11,12}.
$d->union(0, 1);
$d->union(1, 2);
$d->union(2, 3);
$d->union(10, 11);
$d->union(11, 12);
printf "parent: 5 unions, num_sets=%d fd=%d\n", $d->num_sets, $fd;
printf "parent: 0 and 12 connected? %s\n", $d->connected(0, 12) ? 'yes' : 'no';

my $pid = fork // die "fork: $!";
if ($pid == 0) {
    # Child: the memfd is inherited across fork (CLOEXEC only closes on exec).
    my $c = Data::DisjointSet::Shared->new_from_fd($fd);
    printf "child:  sees num_sets=%d from parent\n", $c->num_sets;
    $c->union(3, 10);     # bridge the two parent groups into one component
    $c->union(20, 21);    # a brand-new friendship
    printf "child:  added 2 unions, num_sets now=%d\n", $c->num_sets;
    _exit(0);
}
waitpid($pid, 0);

printf "parent: after child, num_sets=%d\n", $d->num_sets;
printf "parent: 0 and 12 connected now? %s\n", $d->connected(0, 12) ? 'yes' : 'no';
printf "parent: 0 and 20 connected?     %s\n", $d->connected(0, 20) ? 'yes' : 'no';
printf "parent: 0's component has %d members\n", $d->set_size(0);
