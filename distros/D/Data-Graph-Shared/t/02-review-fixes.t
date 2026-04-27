use strict;
use warnings;
use Test::More;
use Data::Graph::Shared;

# Regression: set_node_data must bump stat_ops (was missing).
{
    my $g = Data::Graph::Shared->new(undef, 4, 4);
    my $a = $g->add_node(10);
    my $ops_before = $g->stats->{ops};
    $g->set_node_data($a, 99);
    cmp_ok $g->stats->{ops}, '>', $ops_before, 'set_node_data bumps stat_ops';
}

# Bitmap atomicity: writes via add/remove under mutex must remain
# consistent with lock-free has_node readers. Functional smoke test.
{
    my $g = Data::Graph::Shared->new(undef, 128, 128);
    my @ids = map { $g->add_node($_) } 0 .. 63;
    ok $g->has_node($_), "bitmap atomic alloc bit $_" for @ids[0, 17, 31, 63];
    $g->remove_node($ids[17]);
    ok !$g->has_node($ids[17]), 'bitmap atomic free';
    ok $g->has_node($ids[16]), 'neighboring bit preserved';
    ok $g->has_node($ids[18]), 'neighboring bit preserved (upper)';
}

# remove_node_full: splices incoming edges.
{
    my $g = Data::Graph::Shared->new(undef, 4, 4);
    my $a = $g->add_node(1);
    my $b = $g->add_node(2);
    my $c = $g->add_node(3);
    $g->add_edge($a, $b, 10);     # A → B
    $g->add_edge($c, $b, 20);     # C → B
    $g->add_edge($a, $c,  5);     # A → C
    is $g->edge_count, 3, 'three edges';

    # Plain remove_node(B) leaves A→B and C→B dangling.
    # remove_node_full(B) should drop both.
    ok $g->remove_node_full($b), 'remove_node_full returns true';
    ok !$g->has_node($b), 'B removed';
    is $g->edge_count, 1, 'only A→C remains (incoming B edges spliced)';

    my @nbrs_a = $g->neighbors($a);
    is scalar @nbrs_a, 1, 'A has only one neighbor left';
    is $nbrs_a[0][0], $c, 'A now only points to C';
    is $g->degree($c), 0, 'C has no outgoing edges';
}

# remove_node_full edge cases.
{
    my $g = Data::Graph::Shared->new(undef, 8, 8);
    my $a = $g->add_node(1);
    my $b = $g->add_node(2);

    # No outgoing, no incoming edges.
    ok $g->remove_node_full($a), 'remove_node_full: isolated node';
    ok !$g->has_node($a), 'isolated node removed';

    # Non-existent index → false.
    ok !$g->remove_node_full(42), 'remove_node_full: non-existent returns false';

    # Self-loop: outgoing edge is freed by inner remove_node_locked
    # (outer splice skips src == node).
    my $c = $g->add_node(3);
    ok $g->add_edge($c, $c, 7), 'self-loop';
    is $g->edge_count, 1;
    ok $g->remove_node_full($c), 'remove_node_full: self-loop';
    is $g->edge_count, 0, 'self-loop edge freed';
}

done_testing;
