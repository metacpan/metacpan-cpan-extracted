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
# $Id: SDRF.pm 369 2012-07-17 18:01:48Z tfrayner $

package Bio::MAGETAB::SDRF;

use Moose;
use MooseX::FollowPBP;

use MooseX::Types::Moose qw( ArrayRef );
use Bio::MAGETAB::Types qw( Uri );
use Carp;
use Storable qw( dclone );

BEGIN { extends 'Bio::MAGETAB::BaseClass' };

has 'sdrfRows'            => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::SDRFRow'],
                               auto_deref => 1,
                               clearer    => 'clear_sdrfRows',
                               predicate  => 'has_sdrfRows',
                               required   => 0 );

has 'uri'                 => ( is         => 'rw',
                               isa        => Uri,
                               coerce     => 1,
                               required   => 1 );

sub add_nodes {

    my ( $self, $nodes ) = @_;

    unless ( UNIVERSAL::isa( $nodes, 'ARRAY' ) ) {
        confess("Error: argument to add_nodes must be an array ref.");
    }

    require Bio::MAGETAB::SDRFRow;

    my @rows = $self->get_sdrfRows();

    # FIXME ideally we'd intelligently add new nodes to old rows where
    # applicable, but for now we ignore that use case.

    # First find all the starting nodes. These are the ones with no 
    my @input_nodes = grep { ! $_->has_inputEdges() } @$nodes;

    # Generate the rows from the appropriate lists of nodes. 
    foreach my $node ( @input_nodes ) {
        my $nodelists = $self->_rows_from_node( $node );
        foreach my $list ( @{ $nodelists } ) {

            # Create the actual SDRFRow object.
            my $row = Bio::MAGETAB::SDRFRow->new(
                nodes => $list,
            );

            # We attempt to identify the channel used for this row here.
            if ( my $channel = $self->_get_channel_from_row( $list ) ) {
                $row->set_channel( $channel );
            }

            # FIXME consider also adding FactorValue (probably not
            # practical) and rowNumber (probably not useful).

            push @rows, $row;
        }
    }

    # Check that all the nodes have been assigned; this will
    # probably only be the case if there were no cycles in the graph.
    my %used = map { $_ => 1 } map { $_->get_nodes() } @rows;
    foreach my $node ( @{ $nodes } ) {
        unless ( $used{ $node } ) {
            croak("Error: Unable to assign all nodes to rows (probably"
                . " due to a cycle present in the node-edge graph.");
        }
    }

    $self->set_sdrfRows( \@rows );

    return;
}

sub _rows_from_node {

    my ( $self, $node, $seen ) = @_;

    # Recurse through the node-edge graph to generate a list of rows.

    # We need a mechanism to check for cycles in the graph (this is a
    # hashref to track all the nodes in a given row).
    $seen ||= {};
    if ( $seen->{ $node } ) {
        croak("Error: Cycle detected in the node-edge graph. Unable to continue.");
    }
    $seen->{ $node }++;

    my @list_of_rows;
    my @edges = $node->get_outputEdges();
    if ( scalar @edges ) {

        # Recurse into each edge and gather all the sub-rows.
        foreach my $edge ( @edges ) {

            # Avoid problems caused by splitting and then recombining in the graph.
            my $local_seen  = dclone( $seen );

            my $subrow_list = $self->_rows_from_node( $edge->get_outputNode(), $local_seen );
            foreach my $subrow ( @{ $subrow_list } ) {
                unshift( @$subrow, $node );
            }
            push @list_of_rows, @{ $subrow_list };
        }
    }
    else {

        # Recursion endpoint.
        push @list_of_rows, [ $node ];
    }

    return \@list_of_rows;
}

sub _get_channel_from_row {

    my ( $self, $row ) = @_;
    
    my @labels = map { $_->get_label() }
                 grep { UNIVERSAL::isa( $_, 'Bio::MAGETAB::LabeledExtract')  }
                 @$row;
    my $channel;
    if ( my $num = scalar @labels ) {
        if ( $num > 1 ) {
            croak("Error: Row contains multiple Labeled Extracts. This is"
                . " unsupported by the Bio::MAGETAB model, and should probably"
                . " be split into multiple branches of the experiment design graph.");
        }
        my $val = $labels[0]->get_value();
        require Bio::MAGETAB::ControlledTerm;
        $channel = Bio::MAGETAB::ControlledTerm->new(
            category => 'Channel',    # FIXME hard-coded.
            value    => $val,
        );
    }

    return $channel;
}

__PACKAGE__->meta->make_immutable();

no Moose;

=pod

=head1 NAME

Bio::MAGETAB::SDRF - MAGE-TAB SDRF class

=head1 SYNOPSIS

 use Bio::MAGETAB::SDRF;

=head1 DESCRIPTION

This class is used to describe the SDRFs used in a given
investigation. See the L<BaseClass|Bio::MAGETAB::BaseClass> class for superclass methods.

=head1 ATTRIBUTES

=over 2

=item uri (required)

The URI specifying the location of the SDRF (data type: Uri).

=item sdrfRows (optional)

A list of SDRFRow objects which describe the row structure of the
SDRF. In so doing, these SDRFRows link the SDRF nodes to their
respective investigation, factor value and channel (data type:
Bio::MAGETAB::SDRFRow).

=back

=head1 METHODS

=over 2

=item add_nodes

Passed an arrayref of Node objects, this method automatically sorts
them into SDRFRow objects, which it then stores. Currently this method
is not intelligent enough to sort Nodes into pre-existing SDRFRows, so
it is recommended to use this method only once you have created all
your Nodes (this may be fixed in a subsequent release).

=back

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
