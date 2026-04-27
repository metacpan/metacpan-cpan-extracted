use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);
use Data::Graph::Shared;

my $WORKERS = $ENV{STRESS_WORKERS} || 4;
my $OPS     = $ENV{STRESS_OPS}     || 5_000;
diag "stress: $WORKERS workers x $OPS add_node+add_edge+remove_node each";

my $g = Data::Graph::Shared->new(undef, $WORKERS * $OPS, $WORKERS * $OPS * 2);
my $t0 = time;
my @pids;
for my $w (1..$WORKERS) {
    my $pid = fork // die;
    if ($pid == 0) {
        for (1..$OPS) {
            my $n = $g->add_node($$);
            if (defined $n && $n > 0) {
                $g->add_edge($n, $n - 1, 1);
            }
        }
        _exit(0);
    }
    push @pids, $pid;
}
my $fails = 0;
waitpid($_, 0), $fails += $? != 0 for @pids;
my $dt = time - $t0;

is $fails, 0, "no worker failures";
ok $g->node_count > 0, "nodes created: " . $g->node_count;
ok $g->edge_count > 0, "edges created: " . $g->edge_count;
diag sprintf "%.0f ops/s (%.3fs)", $WORKERS * $OPS / $dt, $dt;

done_testing;
