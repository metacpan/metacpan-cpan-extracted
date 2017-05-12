package Tests::ObjectsAsNodes;

use common::sense;

use Test::Most;
use base 'Test::Class';

use Algorithm::Functional::BFS;

# The graph we're going to search:
#
# A -- B -- C
# |    |    |
# D ---+--- E -- F
# |         |    |
# G         H -- I -- J -- K
#
# For these tests, the haystack will be used only as an organizational tool.
# Navigation across the graph will be performed with object methods.
my %haystack =
(
    A => Node->new(name => q{A}),
    B => Node->new(name => q{B}),
    C => Node->new(name => q{C}),
    D => Node->new(name => q{D}),
    E => Node->new(name => q{E}),
    F => Node->new(name => q{F}),
    G => Node->new(name => q{G}),
    H => Node->new(name => q{H}),
    I => Node->new(name => q{I}),
    J => Node->new(name => q{J}),
    K => Node->new(name => q{K}),
);
$haystack{A}->set_adjacent_nodes([ @haystack{'B', 'D'} ]);
$haystack{B}->set_adjacent_nodes([ @haystack{'A', 'C', 'D', 'E'} ]);
$haystack{C}->set_adjacent_nodes([ @haystack{'B', 'E'} ]);
$haystack{D}->set_adjacent_nodes([ @haystack{'A', 'B', 'E', 'G'} ]);
$haystack{E}->set_adjacent_nodes([ @haystack{'B', 'C', 'D', 'F', 'H'} ]);
$haystack{F}->set_adjacent_nodes([ @haystack{'E', 'I'} ]);
$haystack{G}->set_adjacent_nodes([ $haystack{'D'} ]);
$haystack{H}->set_adjacent_nodes([ @haystack{'E', 'I'} ]);
$haystack{I}->set_adjacent_nodes([ @haystack{'F', 'H', 'J'} ]);
$haystack{J}->set_adjacent_nodes([ @haystack{'I', 'K'} ]);
$haystack{K}->set_adjacent_nodes([ $haystack{'J'} ]);

my $adjacent_nodes_func = sub
{
    my ($node) = @_;
    return $node->get_adjacent_nodes();
};

sub search_long : Tests(2)
{
    my $start_node = $haystack{A};
    my $end_node = $haystack{J};

    my $victory_func = sub { shift->get_name() eq $end_node->get_name() };

    my $bfs = Algorithm::Functional::BFS->new
    (
        adjacent_nodes_func => $adjacent_nodes_func,
        victory_func        => $victory_func,
    );

    my $routes_ref = $bfs->search($start_node);
    is(scalar(@$routes_ref), 1, 'correct number of routes');
    is(scalar(@{$routes_ref->[0]}), 6, 'route has correct length');
}

package Node;

use common::sense;

sub new
{
    my ($class, %args) = @_;

    my %self =
    (
        name           => $args{name},
        adjacent_nodes => $args{adjacent_nodes},
    );

    return bless(\%self, $class);
}

sub get_name
{
    my ($self) = @_;
    return $self->{name};
}

sub set_adjacent_nodes
{
    my ($self, $adjacent_nodes_ref) = @_;
    $self->{adjacent_nodes} = $adjacent_nodes_ref;
}

sub get_adjacent_nodes
{
    my ($self) = @_;
    return $self->{adjacent_nodes};
}

1;
