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
# $Id: Data.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::Data;

use Moose;
use MooseX::FollowPBP;

use Bio::MAGETAB::Types qw( Uri );

BEGIN { extends 'Bio::MAGETAB::Node' };

# This is an abstract class; block direct instantiation.
sub BUILD {

    my ( $self, $params ) = @_;

    if ( blessed $self eq __PACKAGE__ ) {
        confess("ERROR: Attempt to instantiate abstract class " . __PACKAGE__);
    }

    return;
}

has 'uri'                 => ( is       => 'rw',
                               isa      => Uri,
                               coerce   => 1,
                               required => 1 );

has 'dataType'            => ( is       => 'rw',
                               isa      => 'Bio::MAGETAB::ControlledTerm',
                               required => 1 );

__PACKAGE__->meta->make_immutable();

no Moose;

=pod

=head1 NAME

Bio::MAGETAB::Data - Abstract data class

=head1 SYNOPSIS

 use Bio::MAGETAB::Data;

=head1 DESCRIPTION

This class is an abstract class from which all MAGE-TAB Data classes
(DataFile, DataMatrix) are derived. It cannot be instantiated
directly. See the L<Node|Bio::MAGETAB::Node> class for superclass methods.

=head1 ATTRIBUTES

=over 2

=item uri (required)

The URI where the data can be found (data type: Uri).

=item dataType (required)

The type of the data (typically raw or derived; data type:
Bio::MAGETAB::ControlledTerm).

=back

=head1 METHODS

Each attribute has accessor (get_*) and mutator (set_*) methods, and
also predicate (has_*) and clearer (clear_*) methods where the
attribute is optional. Where an attribute represents a one-to-many
relationship the mutator accepts an arrayref and the accessor returns
an array.

=head1 SEE ALSO

L<Bio::MAGETAB::Node>

=head1 AUTHOR

Tim F. Rayner <tfrayner@gmail.com>

=head1 LICENSE

This library is released under version 2 of the GNU General Public
License (GPL).

=cut

1;
