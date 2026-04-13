#!/usr/bin/env perl
# DFS traversal: shared stack enables parallel depth-first exploration
# Multiple workers pop a node, push its children — naturally DFS order
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::Stack::Shared;
$| = 1;

my $nworkers = shift || 2;

# I64 stack — encode (depth, node_id) as depth*10000+id
my $stk = Data::Stack::Shared::Int->new(undef, 1000);

# seed: root node
$stk->push(0 * 10000 + 1);  # depth=0, id=1

my @pids;
for my $w (1..$nworkers) {
    my $pid = fork // die;
    if ($pid == 0) {
        my $visited = 0;
        while (1) {
            my $v = $stk->pop_wait(0.2);
            last unless defined $v;
            my $depth = int($v / 10000);
            my $id    = $v % 10000;
            $visited++;

            # generate children (binary tree, max depth 4)
            if ($depth < 4) {
                $stk->push(($depth + 1) * 10000 + $id * 2);
                $stk->push(($depth + 1) * 10000 + $id * 2 + 1);
            }
        }
        printf "worker %d visited %d nodes\n", $w, $visited;
        _exit(0);
    }
    push @pids, $pid;
}
waitpid($_, 0) for @pids;

# tree has 1+2+4+8+16 = 31 nodes
printf "stack empty: %s\n", $stk->is_empty ? "yes" : "no";
