package Test::MultiRoute;

use common::sense;

use Test::Most;
use base 'Test::Class';

use Algorithm::Functional::BFS;

# The graph we're going to search:
#
# A -- B -- C -- D
# |              |
# >--- E -- F ---<
#           |
#           G
#
# The left- and right-facing chevrons indicate corners.
#
# There are two equidistant routes from A to D in this graph.  There are also
# two routes from A to G, but A-E-F-G is the shorter one.
my %haystack =
(
    A => { name => 'A', adjacent => [ qw(B E) ] },
    B => { name => 'B', adjacent => [ qw(A C) ] },
    C => { name => 'C', adjacent => [ qw(B D) ] },
    D => { name => 'D', adjacent => [ qw(C F) ] },
    E => { name => 'E', adjacent => [ qw(A F) ] },
    F => { name => 'F', adjacent => [ qw(E D G) ] },
    G => { name => 'G', adjacent => [ qw(F) ] },
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

# Retrieve only one result from A to D.
sub search_one_result_equidistant : Tests(1)
{
    my $start_node_name = q{A};
    my $end_node_name = q{D};

    my $victory_func = sub { shift->{name} eq $end_node_name };

    my $bfs = Algorithm::Functional::BFS->new
    (
        adjacent_nodes_func => $adjacent_nodes_func,
        victory_func        => $victory_func,
        one_result          => 1,
    );

    my $routes_ref = $bfs->search($haystack{$start_node_name});
    is(scalar(@$routes_ref), 1, 'correct number of routes');
}

# Retrieve all routes from A to D.
sub search_all_results_equidistant : Tests(1)
{
    my $start_node_name = q{A};
    my $end_node_name = q{D};

    my $victory_func = sub { shift->{name} eq $end_node_name };

    my $bfs = Algorithm::Functional::BFS->new
    (
        adjacent_nodes_func => $adjacent_nodes_func,
        victory_func        => $victory_func,
    );

    my $routes_ref = $bfs->search($haystack{$start_node_name});
    is(scalar(@$routes_ref), 2, 'correct number of routes');
}

# Retrieve all routes from A to G.
sub search_all_results_nonequidistant : Tests(1)
{
    my $start_node_name = q{A};
    my $end_node_name = q{G};

    my $victory_func = sub { shift->{name} eq $start_node_name };

    my $bfs = Algorithm::Functional::BFS->new
    (
        adjacent_nodes_func => $adjacent_nodes_func,
        victory_func        => $victory_func,
    );

    my $routes_ref = $bfs->search($haystack{$end_node_name});
    is(scalar(@$routes_ref), 1, 'correct number of routes');
}

1;
