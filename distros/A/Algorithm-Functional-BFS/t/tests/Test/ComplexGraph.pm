package Test::ComplexGraph;

use common::sense;

use Test::Most;
use base 'Test::Class';

use Algorithm::Functional::BFS;

# The graph we're going to search:
#
# A -- B -- C -- D -- E -- F -- G -- H
# |                   |
# I ------- J ------- K
#           |         |
#           L -- M -- N -- O -- P
my %haystack =
(
    A => { name => 'A', adjacent => [ qw(B I) ] },
    B => { name => 'B', adjacent => [ qw(A C) ] },
    C => { name => 'C', adjacent => [ qw(B D) ] },
    D => { name => 'D', adjacent => [ qw(C E) ] },
    E => { name => 'E', adjacent => [ qw(D F K) ] },
    F => { name => 'F', adjacent => [ qw(E G) ] },
    G => { name => 'G', adjacent => [ qw(F H) ] },
    H => { name => 'H', adjacent => [ qw(G) ] },
    I => { name => 'I', adjacent => [ qw(A J) ] },
    J => { name => 'J', adjacent => [ qw(I K L) ] },
    K => { name => 'K', adjacent => [ qw(E J N) ] },
    L => { name => 'L', adjacent => [ qw(J M) ] },
    M => { name => 'M', adjacent => [ qw(L N) ] },
    N => { name => 'N', adjacent => [ qw(K M O) ] },
    O => { name => 'O', adjacent => [ qw(N P) ] },
    P => { name => 'P', adjacent => [ qw(O) ] },
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

sub traverse_big : Tests(9)
{
    # Our victory condition is finding the node named "P".
    my $victory_func = sub { shift->{name} eq 'P' };

    my $bfs = Algorithm::Functional::BFS->new
    (
        adjacent_nodes_func => $adjacent_nodes_func,
        victory_func        => $victory_func
    );

    # Start the search at the node named "A".
    my $routes_ref = $bfs->search($haystack{A});
    is(scalar(@$routes_ref), 1, 'correct number of routes');

    my @route = @{$routes_ref->[0]};
    my @expected_route = map { $haystack{$_} } qw(A I J K N O P);
    is(scalar(@route), scalar(@expected_route), 'correct route length');

    for (my $i = 0; $i < scalar(@route); ++$i)
    {
        is($route[$i], $expected_route[$i], "route node $i correct");
    }
}

1;
