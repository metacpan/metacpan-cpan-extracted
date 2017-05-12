package Test::SingletonGraph;

use common::sense;

use Test::Most;
use base 'Test::Class';

use Algorithm::Functional::BFS;

# This graph has a single node, called "A".
my %haystack =
(
    A => { name => 'A', adjacent => [ qw() ] },
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

sub singleton_route_exclude_start_node : Tests(1)
{
    my $start_node_name = q{A};
    my $end_node_name = q{A};

    my $victory_func = sub { shift->{name} eq $start_node_name };

    my $bfs = Algorithm::Functional::BFS->new
    (
        adjacent_nodes_func => $adjacent_nodes_func,
        victory_func        => $victory_func,
    );

    my $routes_ref = $bfs->search($haystack{$end_node_name});
    is(scalar(@$routes_ref), 0, 'correct number of routes');
}

sub singleton_route_include_start_node : Tests(1)
{
    my $start_node_name = q{A};
    my $end_node_name = q{A};

    my $victory_func = sub { shift->{name} eq $start_node_name };

    my $bfs = Algorithm::Functional::BFS->new
    (
        adjacent_nodes_func => $adjacent_nodes_func,
        victory_func        => $victory_func,
        include_start_node  => 1,
    );

    my $routes_ref = $bfs->search($haystack{$end_node_name});
    is(scalar(@$routes_ref), 1, 'correct number of routes');
}

1;
