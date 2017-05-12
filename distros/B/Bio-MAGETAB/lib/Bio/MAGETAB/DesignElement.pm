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
# $Id: DesignElement.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::DesignElement;

use Moose;
use MooseX::FollowPBP;

use MooseX::Types::Moose qw( Str Int );

BEGIN { extends 'Bio::MAGETAB::BaseClass' };

# This is an abstract class; block direct instantiation.
sub BUILD {

    my ( $self, $params ) = @_;

    if ( blessed $self eq __PACKAGE__ ) {
        confess("ERROR: Attempt to instantiate abstract class " . __PACKAGE__);
    }

    return;
}

# FIXME these probably don't belong in this superclass; consider
# moving them to e.g. Reporter, or even their own 'Coordinate'
# subclass.
has 'chromosome'          => ( is         => 'rw',
                               isa        => Str,
                               clearer    => 'clear_chromosome',
                               predicate  => 'has_chromosome',
                               required   => 0 );

has 'startPosition'       => ( is         => 'rw',
                               isa        => Int,
                               clearer    => 'clear_startPosition',
                               predicate  => 'has_startPosition',
                               required   => 0 );

has 'endPosition'         => ( is         => 'rw',
                               isa        => Int,
                               clearer    => 'clear_endPosition',
                               predicate  => 'has_endPosition',
                               required   => 0 );

__PACKAGE__->meta->make_immutable();

no Moose;

=pod

=head1 NAME

Bio::MAGETAB::DesignElement - Abstract design element class

=head1 SYNOPSIS

 use Bio::MAGETAB::DesignElement;

=head1 DESCRIPTION

This class is an abstract class from which all MAGE-TAB DesignElement
classes (Feature, Reporter, CompositeElement) are derived. It cannot
be instantiated directly. See the L<BaseClass|Bio::MAGETAB::BaseClass> class for
superclass methods.

=head1 ATTRIBUTES

=over 2

=item chromosome (optional)

The chromosome from which the design element is derived. This is
primarily used in either the Reporter or CompositeElement subclass to
support coordinate-based design elements in data matrices. It is
possible that these attributes will be moved to a more suitable
subclass in subsequent model versions (data type: String).

=item startPosition (optional)

The start coordinate of the design element on the given chromosome (data
type: Integer).

=item endPosition (optional)

The end coordinate of the design element on the given chromosome (data
type: Integer).

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
