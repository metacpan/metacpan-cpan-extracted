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
# $Id: Node.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::Node;

use Moose;
use MooseX::FollowPBP;

use Scalar::Util qw(weaken);
use List::Util qw(first);

use MooseX::Types::Moose qw( ArrayRef );

BEGIN { extends 'Bio::MAGETAB::BaseClass' };

# This is an abstract class; block direct instantiation.
sub BUILD {

    my ( $self, $params ) = @_;

    if ( blessed $self eq __PACKAGE__ ) {
        confess("ERROR: Attempt to instantiate abstract class " . __PACKAGE__);
    }
        
    if ( defined $params->{'inputEdges'} ) {
        $self->_reciprocate_edges_to_nodes(
            $params->{'inputEdges'},
            'outputNode',
        );
    }
    if ( defined $params->{'outputEdges'} ) {
        $self->_reciprocate_edges_to_nodes(
            $params->{'outputEdges'},
            'inputNode',
        );
    }
    if ( defined $params->{'sdrfRows'} ) {
        $self->_reciprocate_sdrf_rows_to_nodes(
            $params->{'sdrfRows'},
            'nodes',
        );
    }

    return;
}

has 'inputEdges'          => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::Edge'],
                               auto_deref => 1,
                               clearer    => 'clear_inputEdges',
                               predicate  => 'has_inputEdges',
                               required   => 0 );

has 'outputEdges'         => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::Edge'],
                               auto_deref => 1,
                               clearer    => 'clear_outputEdges',
                               predicate  => 'has_outputEdges',
                               required   => 0 );

has 'comments'            => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::Comment'],
                               auto_deref => 1,
                               clearer    => 'clear_comments',
                               predicate  => 'has_comments',
                               required   => 0 );

has 'sdrfRows'            => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::SDRFRow'],
                               auto_deref => 1,
                               clearer    => 'clear_sdrfRows',
                               predicate  => 'has_sdrfRows',
                               required   => 0 );

# We use an "around" method to wrap this, rather than a trigger, so
# that we can search through the old nodes from the old edge
# and remove this node.
around 'set_inputEdges' => sub {

    my ( $attr, $self, $edges ) = @_;

    $self->_reciprocate_edges_to_nodes(
        $edges,
        'outputNode',
    );
};

# We use an "around" method to wrap this, rather than a trigger, so
# that we can search through the old nodes from the old edge
# and remove this node.
around 'set_outputEdges' => sub {

    my ( $attr, $self, $edges ) = @_;

    # Set the appropriate $self attribute to point to $edges.
    $attr->( $self, $edges );

    $self->_reciprocate_edges_to_nodes(
        $edges,
        'inputNode',
    );

    return;
};

around 'set_sdrfRows' => sub {

    my ( $attr, $self, $sdrf_rows ) = @_;

    # Note that we have to handle the implicit delete here where a
    # member of $self->get_sdrfRows is being dropped during an update.
    foreach my $r ( $self->get_sdrfRows() ) {
        unless ( first { $r eq $_ } @$sdrf_rows ) {
            my @new_nodes = grep { $_ ne $self } $r->get_nodes();
            $r->{ 'nodes' } = \@new_nodes;
        }
    }

    # Set the appropriate $self attribute to point to $rows.
    $attr->( $self, $sdrf_rows );

    $self->_reciprocate_sdrf_rows_to_nodes(
        $sdrf_rows,
        'nodes',
    );

    return;
};

around 'clear_sdrfRows' => sub {

    my ( $attr, $self ) = @_;

    foreach my $row ( $self->get_sdrfRows() ) {
        my @new_nodes = grep { $_ ne $self } $row->get_nodes();
        $row->{'nodes'} = \@new_nodes;
    }

    # Make sure we actually delete the sdrfRows.
    $attr->( $self );

    return;
};

# This method is used as a wrapper to ensure that reciprocating
# relationships are maintained, even when updating object attributes.
sub _reciprocate_edges_to_nodes {

    # $edges:       The edges with which $self has a reciprocal relationship.
    # $edge_slot:   The name of the slot pointing from $edge to $self.
    my ( $self, $edges, $edge_slot ) = @_;

    # Make sure $edges points to us. Since Edge->Node is 1..* we can
    # just overwrite the node attribute in the edges without worrying
    # about what else it might have pointed to. The Edge-to-Node
    # association is weakened to break a cicular reference on object
    # destruction.
    weaken $self;
    foreach my $t ( @$edges ) {
        $t->{ $edge_slot } = $self;
    }

    return;
}

# This method is used as a wrapper to ensure that reciprocating
# relationships are maintained, even when updating object attributes.
sub _reciprocate_sdrf_rows_to_nodes {

    # $rows:       The rows with which $self has a reciprocal relationship.
    # $row_slot:   The name of the slot pointing from $row to $self.
    my ( $self, $rows, $row_slot ) = @_;

    my $row_getter  = "get_$row_slot";

    # Make sure $rows points to us.
    foreach my $t ( @$rows ) {
       
        # Make sure $t points to us.
        my @current = $t->$row_getter();
        unless ( first { $_ eq $self } @current ) {
            push @current, $self;
            $t->{ $row_slot } = \@current;
        }
    }

    return;
}

__PACKAGE__->meta->make_immutable();

no Moose;

=pod

=head1 NAME

Bio::MAGETAB::Node - Abstract node class

=head1 SYNOPSIS

 use Bio::MAGETAB::Node;

=head1 DESCRIPTION

This class is an abstract class from which all MAGE-TAB SDRF Node
classes are derived. It cannot be instantiated directly. See the
L<BaseClass|Bio::MAGETAB::BaseClass> class for superclass methods.

=head1 ATTRIBUTES

=over 2

=item inputEdges (optional)

A list of Edges leading into this node (data type:
Bio::MAGETAB::Edge).

=item outputEdges (optional)

A list of Edges leading out of this node (data type:
Bio::MAGETAB::Edge).

=item comments (optional)

A list of user-defined comments for the node (data type:
Bio::MAGETAB::Comment).

=item sdrfRows (optional)

A list of SDRF rows to which this node belongs. This is used to link
channel and factor information to each node in the graph (data type:
Bio::MAGETAB::SDRFRow).

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
