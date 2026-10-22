use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);
use Data::Graph::Shared;

my $WORKERS = $ENV{STRESS_WORKERS} || 4;
my $OPS     = $ENV{STRESS_OPS}     || 5_000;
diag "stress: $WORKERS workers x $OPS mutations with concurrent readers";

my $g = Data::Graph::Shared->new(undef, $WORKERS + 2, $WORKERS * 16);
my $sink = $g->add_node(0);
my $t0 = time;
my @pids;
for my $w (1..$WORKERS) {
    my $pid = fork // die;
    if ($pid == 0) {
        my $ok = eval {
            my $n = $g->add_node($w);
            die "node pool exhausted\n" unless defined $n;
            for (1..$OPS) {
                $g->add_edge($n, $sink, $_) or die "edge pool exhausted\n";
                if ($_ % 16 == 0) {
                    $g->remove_node($n) or die "remove failed\n";
                    $n = $g->add_node($w);
                    die "node pool exhausted\n" unless defined $n;
                }
                $g->degree($n) == $_ % 16 or die "wrong degree\n";
                $g->node_data($n) == $w or die "wrong node data\n";
            }
            $g->remove_node_full($n) or die "full remove failed\n";
            $n = $g->add_node($w);
            die "node pool exhausted\n" unless defined $n;
            $g->add_edge($n, $sink, $w) or die "final edge failed\n";
            1;
        };
        warn $@ unless $ok;
        _exit($ok ? 0 : 1);
    }
    push @pids, $pid;
}
my $fails = 0;
waitpid($_, 0), $fails += $? != 0 for @pids;
my $dt = time - $t0;

is $fails, 0, "no worker failures";
is $g->node_count, $WORKERS + 1, 'node count after concurrent slot reuse';
is $g->edge_count, $WORKERS, 'edge count after concurrent slot reuse';
my @nodes = grep { $_ != $sink } $g->nodes;
is_deeply [sort { $a <=> $b } map { $g->node_data($_) } @nodes],
    [1..$WORKERS], 'each worker retains its node';
for my $n (@nodes) {
    is_deeply [$g->neighbors($n)], [[$sink, $g->node_data($n)]],
        'only the final outgoing edge remains';
}
is $g->degree($sink), 0, 'shared destination has no outgoing edges';
diag sprintf "%.0f ops/s (%.3fs)", $WORKERS * $OPS / $dt, $dt;

done_testing;
