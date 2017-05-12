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
# $Id: SDRFRow.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::SDRFRow;

use Moose;
use MooseX::FollowPBP;

use Scalar::Util qw(weaken);
use List::Util qw(first);

use MooseX::Types::Moose qw( Int ArrayRef );

BEGIN { extends 'Bio::MAGETAB::BaseClass' };

sub BUILD {

    my ( $self, $params ) = @_;

    if ( defined $params->{'nodes'} ) {
        $self->set_nodes( $params->{'nodes'} );
        $self->_reciprocate_nodes_to_sdrf_rows(
            $params->{'nodes'},
            'sdrfRows',
        );
    }

    return;
}

has 'nodes'               => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::Node'],
                               auto_deref => 1,
                               required   => 1 );

has 'rowNumber'           => ( is         => 'rw',
                               isa        => Int,
                               clearer    => 'clear_rowNumber',
                               predicate  => 'has_rowNumber',
                               required   => 0 );

has 'factorValues'        => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::FactorValue'],
                               auto_deref => 1,
                               clearer    => 'clear_factorValues',
                               predicate  => 'has_factorValues',
                               required   => 0 );

has 'channel'             => ( is         => 'rw',
                               isa        => 'Bio::MAGETAB::ControlledTerm',
                               clearer    => 'clear_channel',
                               predicate  => 'has_channel',
                               required   => 0 );

# We use an "around" method to wrap this, rather than a trigger, so
# that we can search through the old edges from the old node
# and remove this edge.
around 'set_nodes' => sub {

    my ( $attr, $self, $nodes ) = @_;

    # Note that we have to handle the implicit delete here where a
    # member of $self->get_sdrfRows is being dropped during an update.
    foreach my $n ( $self->get_nodes() ) {
        unless ( first { $n eq $_ } @$nodes ) {
            my @new_rows = grep { $_ ne $self } $n->get_sdrfRows();
            $n->{ 'sdrfRows' } = \@new_rows;
        }
    }

    # Set the appropriate $self attribute to point to $node.
    $attr->( $self, $nodes );

    $self->_reciprocate_nodes_to_sdrf_rows(
        $nodes,
        'sdrfRows',
    );

};

# This method is used as a wrapper to ensure that reciprocating
# relationships are maintained, even when updating object attributes.
sub _reciprocate_nodes_to_sdrf_rows {

    # $node:        The node with which $self has a reciprocal relationship.
    # $node_slot:   The name of the slot pointing from $node to $self.
    my ( $self, $nodes, $node_slot ) = @_;

    my $node_getter = "get_$node_slot";

    # The Node-to-Row association is weakened to break a cicular
    # reference on object destruction.
    weaken $self;

    # Make sure $rows points to us.
    foreach my $t ( $self->get_nodes() ) {
        my @current = $t->$node_getter();
        unless ( first { $_ eq $self } @current ) {
            push @current, $self;
            $t->{ $node_slot } = \@current;
        }
    }

    return;
}

__PACKAGE__->meta->make_immutable();

no Moose;

=pod

=head1 NAME

Bio::MAGETAB::SDRFRow - MAGE-TAB SDRF row class

=head1 SYNOPSIS

 use Bio::MAGETAB::SDRFRow;

=head1 DESCRIPTION

This class is used to describe the rows in a given MAGE-TAB SDRF
document. Links between Nodes, channel and FactorValue are handled by
this class. See the L<BaseClass|Bio::MAGETAB::BaseClass> class for superclass methods, and the
L<SDRF|Bio::MAGETAB::SDRF> class for its add_nodes method which can be used to
automatically sort Nodes into SDRFRows.

=head1 ATTRIBUTES

=over 2

=item nodes (required)

A list of Node objects associated with this SDRF row (data type:
Bio::MAGETAB::Node).

=item rowNumber (optional)

The number of this row within the SDRF. Rows are assumed to be
numbered from top to bottom, starting at one for the first data
row; however this is not constrained by the model and you may use
whatever local conventions you prefer (data type: Integer).

=item factorValues (optional)

A list of FactorValues associated with this row (data type:
Bio::MAGETAB::FactorValue).

=item channel (optional)

The channel used when labeling and scanning for this row (e.g. 'Cy3',
'biotin', 'alexa_588'), usually taken from a suitable ontology (data
type: Bio::MAGETAB::ControlledTerm).

=back

=head1 METHODS

Each attribute has accessor (get_*) and mutator (set_*) methods, and
also predicate (has_*) and clearer (clear_*) methods where the
attribute is optional. Where an attribute represents a one-to-many
relationship the mutator accepts an arrayref and the accessor returns
an array.

=head1 SEE ALSO

L<Bio::MAGETAB::BaseClass>, L<Bio::MAGETAB::SDRF>

=head1 AUTHOR

Tim F. Rayner <tfrayner@gmail.com>

=head1 LICENSE

This library is released under version 2 of the GNU General Public
License (GPL).

=cut

1;
