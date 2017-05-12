package Algorithm::DependencySolver::Traversal;
$Algorithm::DependencySolver::Traversal::VERSION = '1.01';
use Moose;
use MooseX::FollowPBP;
use MooseX::Method::Signatures;

use List::MoreUtils qw(all uniq);

use Data::Dumper;

=head1 NAME

Algorithm::DependencySolver::Traversal - A module for traversing a dependency graph

=head1 VERSION

version 1.01

=head1 SYNOPSIS

    my $traversal = Algorithm::DependencySolver::Traversal->new(
        Solver => $solver,
        visit  => sub {
            my $operation = shift;
            print "Visited operation: ", $operation->id, "\n";
        },
    );

    $traversal->run;

=head1 DESCRIPTION

Given an L<Algorithm::DependencySolver::Solver.pm> object, traverses it
in such a way that upon entering a node, all of its prerequisites will
have already been entered.

=head2 Concurrency

Currently this module is I<not> thread-safe. However, it has been
design in such a way that it should be easy to allow concurrency at a
later stage, without needing to break backwards compatibility.

Note that if we allow concurrency, the C<visitable> list may be empty,
without indicating that the traversal is complete.

=head1 METHODS

=cut


has 'Solver' => (
    is       => 'ro',
    isa      => 'Algorithm::DependencySolver::Solver',
    required => 1,
);

has 'visitable' => (
    is      => 'rw',
#   isa     => 'ArrayRef[String]',
    default => sub { [] },
);

# indexed by $node->id; value is boolean
has 'visited' => (
    is      => 'ro',
#   isa     => 'HashRef[Bool]',
    default => sub { {} },
);

has 'visit' => (
    is       => 'rw',
    isa      => 'CodeRef',
    default  => sub { sub { 1 } },
);

has 'choose' => (
    is       => 'ro',
    isa      => 'CodeRef',
    default  => sub { sub { shift } },
);



=head2 C<choose>

During the traversal, we maintain a list of nodes, C<visitable>, which
can be immediately visited. If this list is empty, the traversal is
complete.

The C<choose> function is called to decide which node is C<visitable>
to visit next. Note that C<choose> is guaranteed to be called, even if
C<visitable> is a singleton (but not if it's empty).

=cut

method choose() {
    my $size = @{$self->get_visitable};
    die "choose(): precondition for size failed" unless $size;
    my $choice = $self->get_choose->(@{$self->get_visitable});
    die "choose() function didn't make a choice! ($size)"
        unless defined $choice and $choice ne '';
    $self->set_visitable([grep {
        not ($_ eq $choice)
    } @{$self->get_visitable}]);
    my $size_diff = $size - @{$self->get_visitable};
    die "Bad choice; $size_diff" unless $size_diff == 1;
    return $choice;
};

method _add_visitable(@nodes) {
    for my $node (@nodes) { 
        unless (defined $node and $node ne '') {
            die "_add_visitable(): nodes must be defined";
        }
    }
    $self->set_visitable(
        [uniq @nodes, @{$self->get_visitable}]
    );
}

method _can_visit($node_id) {
    return all {
        $self->get_visited->{$_}
    } $self->get_Solver->get_Graph->predecessors($node_id);
};

=head2 dryrun

Create a linear path and return it as an array of the arguments that
would have been passed into the C<visit> function.

Use C<run_path> to run a path created by C<dryrun>.

=cut

method dryrun() {
    my $visit = $self->get_visit;
    my @path;
    $self->set_visit(sub {
        push @path, \@_;
    });
    $self->run();
    $self->set_visit($visit);
    return \@path;
}

method run_path($path) {
    for my $args (@$path) {
        $self->get_visit(@$args);
    }
}

method run() {

    die "Not a valid graph!" if $self->get_Solver->is_invalid;

    my $G = $self->get_Solver->get_Graph;

    $self->_add_visitable($G->predecessorless_vertices);

    while (@{$self->get_visitable}) {
        my $node_id = $self->choose();
        my $node  = $self->get_Solver->get_nodes_index->{$node_id};
        $self->get_visit->($node);
        $self->get_visited->{$node_id} = 1;
        $self->_add_visitable(
            grep { $self->_can_visit($_) } $G->successors($node_id)
        );
    }
};


no Moose;
__PACKAGE__->meta->make_immutable;
