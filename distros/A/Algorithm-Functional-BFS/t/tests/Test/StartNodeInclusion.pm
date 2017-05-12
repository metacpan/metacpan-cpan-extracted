package Test::BoundaryConditions;

use common::sense;

use Test::Most;
use base 'Test::Class';

use Algorithm::Functional::BFS;

# The graph we're going to search:
#
# A -- B -- C
my %haystack =
(
    A => { name => 'A', adjacent => [ qw(B) ] },
    B => { name => 'B', adjacent => [ qw(A C) ] },
    C => { name => 'C', adjacent => [ qw(B) ] },
);

# Each node is a hash ref from the haystack hash.  Adjacent nodes are found by
# dereferencing the current node's list of adjacent nodes and then retrieving
# each of those nodes from the haystack.
my $adjacent_nodes_func = sub
{
    my ($node) = @_;
    my @adjacent_nodes = map { $haystack{$_} } @{$node->{adjacent}};
    return \@adjacent_nodes;
};

# Search for the start node, inclusive of the start node.
sub start_node_include : Tests(3)
{
    my $node_name = q{A};

    my $victory_func = sub { shift->{name} eq $node_name };

    my $bfs = Algorithm::Functional::BFS->new
    (
        adjacent_nodes_func => $adjacent_nodes_func,
        victory_func        => $victory_func,
        include_start_node  => 1,
    );

    my $routes_ref = $bfs->search($haystack{$node_name});
    is(scalar(@$routes_ref), 1, 'correct number of routes');

    my @route = @{$routes_ref->[0]};
    my @expected_route = map { $haystack{$_} } qw(A);
    is(scalar(@route), scalar(@expected_route), 'correct route length');

    for (my $i = 0; $i < scalar(@route); ++$i)
    {
        is($route[$i], $expected_route[$i], "route node $i correct");
    }
}

# Search for the start node, exclusive of the start node.
sub start_node_exclude : Tests(1)
{
    my $node_name = q{A};

    my $victory_func = sub { shift->{name} eq $node_name };

    my $bfs = Algorithm::Functional::BFS->new
    (
        adjacent_nodes_func => $adjacent_nodes_func,
        victory_func        => $victory_func,
        include_start_node  => undef,
    );

    my $routes_ref = $bfs->search($haystack{$node_name});
    is(scalar(@$routes_ref), 0, 'correct number of routes');
}

1;
