# Copyright 2008-2010 Tim Rayner
# 
# This file is part of Bio::MAGETAB.
# 
# Bio::MAGETAB is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
# 
# Bio::MAGETAB is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Bio::MAGETAB.  If not, see <http://www.gnu.org/licenses/>.
#
# $Id: Edge.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::Edge;

use Moose;
use MooseX::FollowPBP;

use List::Util qw(first);

use MooseX::Types::Moose qw( ArrayRef );

BEGIN { extends 'Bio::MAGETAB::BaseClass' };

sub BUILD {

    my ( $self, $params ) = @_;

    if ( defined $params->{'inputNode'} ) {
        $self->_reciprocate_nodes_to_edges(
            $params->{'inputNode'},
            'inputNode',
            'outputEdges',
        );
    }
    if ( defined $params->{'outputNode'} ) {
        $self->_reciprocate_nodes_to_edges(
            $params->{'outputNode'},
            'outputNode',
            'inputEdges',
        );
    }

    return;
}

has 'inputNode'            => ( is         => 'rw',
                                isa        => 'Bio::MAGETAB::Node',
                                weak_ref   => 1,
                                required   => 1 );

has 'outputNode'           => ( is         => 'rw',
                                isa        => 'Bio::MAGETAB::Node',
                                weak_ref   => 1,
                                required   => 1 );

has 'protocolApplications' => ( is         => 'rw',
                                isa        => ArrayRef['Bio::MAGETAB::ProtocolApplication'],
                                auto_deref => 1,
                                clearer    => 'clear_protocolApplications',
                                predicate  => 'has_protocolApplications',
                                required   => 0 );

# We use an "around" method to wrap this, rather than a trigger, so
# that we can search through the old edges from the old node
# and remove this edge.
around 'set_inputNode' => sub {

    my ( $attr, $self, $node ) = @_;

    # Note that we have to handle the implicit delete here where a
    # member of $self->get_inputNode is being dropped during an update.
    my $old_node = $self->get_inputNode();
    if ( $old_node && $node ne $old_node ) {
        my @new_rows = grep { $_ ne $self } $old_node->get_outputEdges();
        $old_node->{ 'outputEdges' } = \@new_rows;
    }

    # Set the appropriate $self attribute to point to $node.
    $attr->( $self, $node );

    $self->_reciprocate_nodes_to_edges(
        $node,
        'inputNode',
        'outputEdges',
    );
};

# We use an "around" method to wrap this, rather than a trigger, so
# that we can search through the old edges from the old node
# and remove this edge.
around 'set_outputNode' => sub {

    my ( $attr, $self, $node ) = @_;

    # Note that we have to handle the implicit delete here where a
    # member of $self->get_outputNode is being dropped during an update.
    my $old_node = $self->get_outputNode();
    if ( $old_node && $node ne $old_node ) {
        my @new_rows = grep { $_ ne $self } $old_node->get_inputEdges();
        $old_node->{ 'inputEdges' } = \@new_rows;
    }

    # Set the appropriate $self attribute to point to $node.
    $attr->( $self, $node );

    $self->_reciprocate_nodes_to_edges(
        $node,
        'outputNode',
        'inputEdges',
    );
};

# This method is used as a wrapper to ensure that reciprocating
# relationships are maintained, even when updating object attributes.
sub _reciprocate_nodes_to_edges {

    # $node:        The node with which $self has a reciprocal relationship.
    #                 This can be either a scalar or an arrayref.
    # $self_slot:   The name of the slot pointing from $self to $node.
    # $node_slot:   The name of the slot pointing from $node to $self.
    my ( $self, $node, $self_slot, $node_slot ) = @_;

    my $self_getter = "get_$self_slot";
    my $node_getter = "get_$node_slot";

    # Remove $self from the list held by the old $node.
    my $old_node = $self->$self_getter();
    if ( $old_node ) {

        my @cleaned;
        foreach my $item ( $old_node->$node_getter() ) {
            push @cleaned, $item unless ( $item eq $self );
        }
        $old_node->{ $node_slot } = \@cleaned;
    }

    # Make sure $node points to us.
    my @current = $node->$node_getter();
    unless ( first { $_ eq $self } @current ) {
        push @current, $self;
        $node->{ $node_slot } = \@current;
    }

    return;
}

__PACKAGE__->meta->make_immutable();

no Moose;

=pod

=head1 NAME

Bio::MAGETAB::Edge - MAGE-TAB edge class

=head1 SYNOPSIS

 use Bio::MAGETAB::Edge;

=head1 DESCRIPTION

This class is used to store information on edges in the experimental
design graph described by a MAGE-TAB SDRF. Each Edge must link to both
an input and an output Node. See the L<BaseClass|Bio::MAGETAB::BaseClass> class for superclass
methods.

=head1 ATTRIBUTES

=over 2

=item inputNode (required)

The Node object which feeds into this edge (data type:
Bio::MAGETAB::Node).

=item outputNode (required)

The Node object leading away from this edge (data type:
Bio::MAGETAB::Node)

=item protocolApplications (optional)

A list of ProtocolApplications associated with the edge (data type:
Bio::MAGETAB::ProtocolApplication).

=back

=head1 METHODS

Each attribute has accessor (get_*) and mutator (set_*) methods, and
also predicate (has_*) and clearer (clear_*) methods where the
attribute is optional. Where an attribute represents a one-to-many
relationship the mutator accepts an arrayref and the accessor returns
an array.

=head1 SEE ALSO

L<Bio::MAGETAB::BaseClass>

=head1 AUTHOR

Tim F. Rayner <tfrayner@gmail.com>

=head1 LICENSE

This library is released under version 2 of the GNU General Public
License (GPL).

=cut

1;
