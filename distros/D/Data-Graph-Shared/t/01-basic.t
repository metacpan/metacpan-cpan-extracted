use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use POSIX qw(_exit);
use Data::Graph::Shared;

my $g = Data::Graph::Shared->new(undef, 10, 20);
ok $g, 'created';
is $g->node_count, 0;
is $g->edge_count, 0;
is $g->max_nodes, 10;
is $g->max_edges, 20;

# add nodes
my $a = $g->add_node(100);
my $b = $g->add_node(200);
my $c = $g->add_node(300);
ok defined $a, 'add_node a';
ok defined $b, 'add_node b';
ok defined $c, 'add_node c';
is $g->node_count, 3;

# node data
is $g->node_data($a), 100;
is $g->node_data($b), 200;
$g->set_node_data($a, 111);
is $g->node_data($a), 111;

# has_node
ok $g->has_node($a);
ok !$g->has_node(99);

# add edges
ok $g->add_edge($a, $b, 5), 'a->b weight 5';
ok $g->add_edge($a, $c, 3), 'a->c weight 3';
ok $g->add_edge($b, $c, 1), 'b->c weight 1';
is $g->edge_count, 3;

# neighbors
my @nbrs = $g->neighbors($a);
is scalar @nbrs, 2, 'a has 2 neighbors';
# neighbors returns [dst, weight] pairs
my %n = map { $_->[0] => $_->[1] } @nbrs;
is $n{$b}, 5, 'a->b weight';
is $n{$c}, 3, 'a->c weight';

# degree
is $g->degree($a), 2;
is $g->degree($b), 1;
is $g->degree($c), 0;

# each_neighbor
my @found;
$g->each_neighbor($a, sub { push @found, [$_[0], $_[1]] });
is scalar @found, 2, 'each_neighbor';

# nodes list
my @nodes = $g->nodes;
is scalar @nodes, 3, 'nodes list';

# remove node
ok $g->remove_node($b), 'remove b';
is $g->node_count, 2;
ok !$g->has_node($b);
# b's outgoing edge (b->c) was removed
is $g->edge_count, 2, 'a edges remain, b edges removed';

# add edge to non-existent node fails
ok !$g->add_edge($b, $c, 1), 'add_edge to removed node fails';

# cross-process
my $pid = fork // die;
if ($pid == 0) {
    _exit($g->node_data($a) == 111 ? 0 : 1);
}
waitpid($pid, 0);
is $? >> 8, 0, 'cross-process read';

# file persistence
my $path = tmpnam() . '.shm';
{
    my $fg = Data::Graph::Shared->new($path, 10, 20);
    my $x = $fg->add_node(42);
    my $y = $fg->add_node(43);
    $fg->add_edge($x, $y, 7);
}
{
    my $fg = Data::Graph::Shared->new($path, 10, 20);
    is $fg->node_count, 2, 'persistence node_count';
    is $fg->edge_count, 1, 'persistence edge_count';
    is $fg->path, $path, 'path accessor';
}
unlink $path;

# edge default weight
$g->add_edge($a, $c);  # default weight=1
@nbrs = $g->neighbors($a);
my @weights = sort map { $_->[1] } @nbrs;
ok(grep({ $_ == 1 } @weights), 'default weight=1');

# stats
my $gs = $g->stats;
ok ref $gs eq 'HASH', 'stats returns hashref';
ok $gs->{node_count} > 0, 'stats node_count';
ok $gs->{ops} > 0, 'stats ops';

done_testing;
