package Algorithm::DependencySolver::Solver;
$Algorithm::DependencySolver::Solver::VERSION = '1.01';
use Moose;
use MooseX::FollowPBP;
use MooseX::Method::Signatures;

use List::Compare;
use List::MoreUtils qw(any);

use Graph::Directed;
use Graph::Easy;
use Graph::Convert;


=head1 NAME

Algorithm::DependencySolver - A dependency solver for scheduling access to a shared resource

=head1 VERSION

version 1.01

=head1 SYNOPSIS

    use Algorithm::DependencySolver::Solver;
    use Algorithm::DependencySolver::Traversal;
    use Algorithm::DependencySolver::Operation;

    my @operations = (
        Algorithm::DependencySolver::Operation->new(
            id            => 1,
            depends       => [qw(z)],
            affects       => [qw(x)],
            prerequisites => ["3"],
        ),
        Algorithm::DependencySolver::Operation->new(
            id            => 2,
            depends       => [qw(x)],
            affects       => [qw(y)],
            prerequisites => [],
        ),
        Algorithm::DependencySolver::Operation->new(
            id            => 3,
            depends       => [qw(y)],
            affects       => [qw(z)],
            prerequisites => [],
        ),
    );

    my $solver =
        Algorithm::DependencySolver::Solver->new(nodes => \@operations);

    $solver->to_png("pretty-graph.png");



    my $traversal = Algorithm::DependencySolver::Traversal->new(
        Solver => $solver,
        visit  => sub {
            my $operation = shift;
            print "Visited operation: ", $operation->id, "\n";
        },
    );

    $traversal->run;

=head1 DESCRIPTION

This dependency solver is somewhat different to the existing
L<Algorithm::Dependency> module.

L<Algorithm::Dependency> creates a heirarchy where each node depends
on a set of other nodes. In L<Algorithm::DependencySolver>, there
exists a set of operations and a set of resources, with a set of edges
from operations to resources (the dependencies), and a set of edges
from resources to operations (the affects). Given this input, the
module outputs a directed acyclic graph (DAG) containing just the
operations as its nodes.

Aditionally, L<Algorithm::DependencySolver> allows for input which
whould have resulted in a cyclic output graph to be resolved by means
of explicit sequencing. This is done by marking nodes as depending on
other nodes. See
L<Algorithm::DependencySolver::Operation::prerequisites>.


=head1 METHODS

=cut



has 'nodes' => (
    is       => 'ro',
#   isa      => 'ArrayRef[Operation]',
    required => 1,
);

has 'nodes_index' => (
    is       => 'ro',
#   isa      => 'HashRef[Operation]',
    builder  => 'build_nodes_index',
    lazy     => 1,
    init_arg => undef,
);

has 'relations' => (
    is       => 'ro',
    builder  => 'build_relations',
    lazy     => 1,
    init_arg => undef,
);

has 'affects_index' => (
    is       => 'ro',
    builder  => 'build_affects_index',
    lazy     => 1,
    init_arg => undef,
);

=head2 get_Graph

Returns the dependency graph as a L<Graph> object. Note that only
operations are included in the graph, not resources. This is of most
use to the L<Algorithm::DependencySolver::Traversal> module, and the
C<to_dot> and C<to_png> methods.

=cut

has 'Graph' => (
    is       => 'ro',
    builder  => 'build_Graph',
    lazy     => 1,
    init_arg => undef,
);

has 'GraphEasy' => (
    is       => 'ro',
    builder  => 'build_GraphEasy',
    lazy     => 1,
    init_arg => undef,
);


method build_nodes_index() {
    return { map { $_->id => $_ } @{$self->get_nodes} };
}

method build_relations() {

    my @relations;

    for my $node (@{$self->get_nodes()}) {
        for my $resource (@{$node->depends}) {
            for my $other (@{$self->get_affects_index->{$resource}}) {
                next if $node->id eq $other->id;
                push @relations, [$other, $node];
            }
        }
    }

    return \@relations;
}


method build_Graph() {

    my @vertices = keys %{$self->get_nodes_index};
    my @edges    = map {
        [ $_->[0]->id, $_->[1]->id ]
    } @{$self->get_relations};

    # Ensure that each explicit ordering (node.prerequisites) has an edge.
    for my $nodeB (@{$self->get_nodes}) {
        for my $nodeA_id (@{$nodeB->prerequisites}) {
            push @edges, [$nodeA_id, $nodeB->id];
        }
    }


    my $G = Graph::Directed->new(
        vertices    => \@vertices,
        edges       => \@edges,
#       refvertexed => 1,  # refvertexed is broken!
    );

    # Note: Graph::Traversal has a bug in it where noderefs are
    # sometimes stringified, even though they mustn't be with
    # refvertexed! Therefore, assume all of Graph is broken in this
    # respect, and never pass in addresses to references, but never
    # references themselves.

    $self->_apply_orderings($G);
    $self->_remove_redundancy($G);

    return $G;
}

method _get_nondeterministic_attributes() {
    my %nondep_affects;

  AFFECT:
    for my $affect (keys %{$self->get_affects_index}) {
        my @node_ids = map {
            $_->id
        } @{$self->get_affects_index->{$affect}};

        next AFFECT unless @node_ids;

        my @sequentials;

        for my $node_id (@node_ids) {
            my @pred_ids = $self->get_Graph->all_predecessors($node_id);
            push @pred_ids, $node_id;
            my $C = List::Compare->new(\@node_ids, \@pred_ids);
            if ($C->is_LsubsetR) {
                # We're good; we have a nice linear ordering
                next AFFECT;
            } else {
                my @intersection = $C->get_intersection;
                if (@intersection > @sequentials) {
                    @sequentials = @intersection;
                }
            }
        }

        # Nondeterministic affect!
        my @nondeps = List::Compare->new(\@node_ids, \@sequentials)->get_unique;
        $nondep_affects{$affect} = {
            sequentials => \@sequentials,
            nondeps     => \@nondeps,
        };
    }
    return keys(%nondep_affects) ? \%nondep_affects : undef;
}

method _get_undepended_affects() {
    my %undeped_affects;

  AFFECT:
    for my $affect (keys %{$self->get_affects_index}) {
        my @nodes = @{$self->get_affects_index->{$affect}};

        next AFFECT unless @nodes;

        for my $node (@nodes) {
            my $f;
            $f = sub {
                my $suc_id = shift;
                my $suc = $self->get_nodes_index->{$suc_id};
                if ($suc->depends($affect)) {
                    # This path is good
                    return [];
                } elsif ($suc->affects($affect)) {
                    # woah
                    return [$suc];
                } else {
                    return [map { @{$f->($_)} } $self->get_Graph->successors($suc_id)];
                }
            };
            my @bad = map { @{$f->($_)} } $self->get_Graph->successors($node->id);
            $undeped_affects{$affect}{$node->id} = \@bad if @bad;
        }
    }
    return keys(%undeped_affects) ? \%undeped_affects : undef;
}

method is_invalid() {
    my $cyclic           = $self->get_Graph->is_cyclic;
    my $nondeterministic = $self->_get_nondeterministic_attributes;
    my $undeped_affects  = $self->_get_undepended_affects;

    my %r;
    $r{cyclic}           = $cyclic           if $cyclic;
    $r{nondeterministic} = $nondeterministic if $nondeterministic;
    $r{undeped_affects}  = $undeped_affects  if $undeped_affects;

    if (keys %r) {
        return \%r;
    } else {
        return;
    }
}

# Safe to call on cyclic graphs. Will not fail early if cycle
# encountered
method _apply_orderings($G) {

    for my $nodeB (@{$self->get_nodes}) {
        for my $nodeA_id (@{$nodeB->prerequisites}) {
            my %seen;
            my $recurse;
            $recurse = sub {
                my $node_id = shift;
                return if $seen{$node_id}++;
                for my $to_id ($G->successors($node_id)) {
                    if ($to_id eq $nodeA_id) {
                        $G->delete_edge($node_id, $to_id);
                    }
                    else {
                        $recurse->($to_id);
                    }
                }
            };
            $recurse->($nodeB->id);
        }
    }
}

=head2 _remove_redundancy

  $self->_remove_redundancy($G);  # Ignore the return value

Applied to a graph object, removes redundant edges. An edge is
redundant if it can be removed without invalidating the graph.

The fundamental law of the dependency graph is that a node can only be
traversed when all of its predecessors have been traversed. 

Given some node, C<$n>, and a predecessor of C<$n>, C<$a>, then it is
safe to remove C<$a> if and only if another node exists, C<$b>, which
is a predecessor of C<$n>, and there is a path from C<$a> to C<$b>
(i.e., traversal of C<$b> requires that C<$a> has been visited).

Note that cycles may cause this algorithm to behave unexpectedly
(depending on what one expects). Consider what happens if C<$n> has
two successors, C<$a> and C<$b>, such that there is a cycle between
C<$a> and C<$b> (i.e., there is an edge from C<$a> to C<$b>, and
vice-versa). Suppose that the edge from C<$n> to C<$a> has been
removed. Can the edge from C<$n> to C<$b> safely be removed?

Using the algorithm described above, yes! This is because there is
another path from C<$n> to C<$b>: C<$n -&gt; $b -&gt; $a -&gt; b>. We
can, of course, detect such occurrences; however, I choose not to,
because it's not clear to me what the most elegant result should be in
these situations. Semantically, it does not matter whether the edge
from C<$n> to the C<$a,$b>-cycle is from C<$n> to C<$a>, or C<$n> to
C<$b>. Which should it be? Both, or one-or-the-other (presumably
decided arbitrarily)?

Properties:

* This method can be safely called on cyclic graphs (i.e., it will not
  enter a non-terminating loop)

* This method will not fail early if a cycle is encountered (i.e., it
  will do as much work as it can, even though the graph is probably
  invalid)

* If C<_apply_orderings> is to be called on the graph object, it
  I<must> be done I<before> calling C<_remove_redundancy>

=cut

method _remove_redundancy($G) {

    for my $node ($G->vertices) {
        for my $pred ($G->predecessors($node)) {
            next unless $G->has_edge($pred, $node);

            my @other_predecessors =
              grep { $_ ne $pred } $G->predecessors($node);

            my $other_paths_to_pred = grep {
                # Returns true only if the edge from $pred to $node can
                # safely be removed
                any { $_ eq $pred } $G->all_predecessors($_);
            } @other_predecessors;

            if ($other_paths_to_pred) {
                $G->delete_edge($pred, $node);
            }
        }
    }
}



method build_affects_index() {
    my %index;
    for my $node (@{$self->get_nodes}) {
        for my $resource (@{$node->affects}) {
            push @{$index{$resource}}, $node;
        }
    }
    return \%index;
}

method to_s() {
    return $self->get_GraphEasy->as_ascii();
}

=head2 to_png

  $solver->to_png($file)

Outputs a dependency graph (showing only operations) to the given file
in PNG format

=cut

method to_png($file) {
    die "Only sane file names, please (you gave: $file)" unless
      $file =~ m/^[a-z0-9_\-\.\/]+$/i;
    open my $dot, "|dot -Tpng -o'$file'" or die ("Cannot open pipe to dot (-o $file): $!");
    print $dot $self->get_GraphEasy->as_graphviz;
}


=head2 to_dot

  $solver->to_dot($file)

Outputs a dependency graph (showing only operations) to the given file
in Graphviz's dot format

=cut

method to_dot($file) {
    die "Only sane file names, please (you gave: $file)" unless
      $file =~ m/^[a-z0-9_\-\.\/]+$/i;
    open my $fh, ">", $file or die ("Cannot open to $file: $!");
    print $fh $self->get_GraphEasy->as_graphviz;
}



method build_GraphEasy() {
    return Graph::Convert->as_graph_easy($self->get_Graph);
}


no Moose;
__PACKAGE__->meta->make_immutable;
