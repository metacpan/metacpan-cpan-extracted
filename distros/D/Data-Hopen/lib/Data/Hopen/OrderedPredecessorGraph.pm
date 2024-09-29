# Data::Hopen::OrderedPredecessorGraph - Graph that keeps predecessors in order
package Data::Hopen::OrderedPredecessorGraph;
use strict;
use Data::Hopen::Base;

our $VERSION = '0.000021';

use parent 'Graph';

# Docs {{{1

=head1 NAME

Data::Hopen::OrderedPredecessorGraph - Graph that tracks the order in which edges are added

=head1 SYNOPSIS

Just like a L<Graph> with two exceptions:

=over

=item *

Every call to L</add_edge> (or other edge-adding routines) tracks the order in
an attribute on that edge; and

=item *

New routine L</ordered_predecessors> returns the predecessors sorted
in the order they were added.

=back

This is unlike L<Graph/predecessors> and L<Graph/edges_to>, which return
the predecessors in random order.

=cut

# }}}1

# Internals

use constant _EDGE_ID => (__PACKAGE__ . '_edge_id');    # attribute name
my $_edge_id = 0;   # unique ID for each edge added.
                    # INTERNAL PRECONDITION: real edge IDs are > 0.

=head1 FUNCTIONS

=head2 add_edge

Add an edge.  Exactly as L<Graph/add_edge> except that it also creates the
new edge attribute to hold the order.  Returns the graph.

L<Graph/add_edges> is implemented using C<add_edge>, so we don't need to
override C<add_edges>.

=cut

sub add_edge {
    croak 'Need instance, from, to' unless @_ == 3;
    my ($self, $from, $to) = @_;
    $self->SUPER::add_edge($from, $to);
    $self->set_edge_attribute($from, $to, _EDGE_ID, ++$_edge_id);
    return $self;
} #todo()

=head2 ordered_predecessors

Return a list of the predecessors of the given vertex, in order that the edges
were added to that vertex.  Exactly as L<Graph/predecessors> except for the
stable order.

=cut

sub ordered_predecessors {
    croak 'Need instance, vertex' unless @_ == 2;
    my ($self, $to) = @_;
    die 'Multiedged graphs are not yet supported' if $self->multiedged;
        # TODO use get_multiedge_ids to get the edge IDs, then get the
        # attributes for each edge, then sort.

    my @p = $self->predecessors($to);
    return sort {
        ( $self->get_edge_attribute($a, $to, _EDGE_ID) // 0 )
                                <=>
        ( $self->get_edge_attribute($b, $to, _EDGE_ID) // 0 )
    } @p;
} #ordered_predecessors()

=head2 add_edge_by_id

Add a multiedge.  Exactly as L<Graph/add_edge_by_id> except that it also
creates the new edge attribute to hold the order.  Returns the graph.
Can only be used on a multiedged graph.

=cut

sub add_edge_by_id {
    croak 'Need self, from, to, id' unless @_ == 4;
    my ($self, $from, $to, $id) = @_;
    $self->SUPER::add_edge_by_id($from, $to, $id);
    $self->set_edge_attribute_by_id($from, $to, $id, _EDGE_ID, ++$_edge_id);
    return $self;
} #add_edge_by_id()

=head2 add_edge_get_id

Add a multiedge.  Exactly as L<Graph/add_edge_get_id> except that it also
creates the new edge attribute to hold the order.  Returns the ID of the
new edge.  Can only be used on a multiedged graph.

=cut

sub add_edge_get_id {
    croak 'Need self, from, to' unless @_ == 3;
    my ($self, $from, $to) = @_;
    my $id = $self->SUPER::add_edge_get_id($from, $to);
    $self->set_edge_attribute_by_id($from, $to, $id, _EDGE_ID, ++$_edge_id);
    return $id;
} #add_edge_get_id()

1;
__END__
# vi: set fdm=marker: #
