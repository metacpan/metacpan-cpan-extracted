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
# $Id: ArrayDesign.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::ArrayDesign;

use Moose;
use MooseX::FollowPBP;

use MooseX::Types::Moose qw(Str ArrayRef);
use Bio::MAGETAB::Types qw(Uri);

BEGIN { extends 'Bio::MAGETAB::DatabaseEntry' };

has 'name'                => ( is         => 'rw',
                               isa        => Str,
                               required   => 1 );

has 'version'             => ( is         => 'rw',
                               isa        => Str,
                               clearer    => 'clear_version',
                               predicate  => 'has_version',
                               required   => 0 );

has 'uri'                 => ( is         => 'rw',
                               isa        => Uri,
                               clearer    => 'clear_uri',
                               predicate  => 'has_uri',
                               coerce     => 1,
                               required   => 0 );

has 'provider'            => ( is         => 'rw',
                               isa        => Str,
                               clearer    => 'clear_provider',
                               predicate  => 'has_provider',
                               required   => 0 );

has 'technologyType'      => ( is         => 'rw',
                               isa        => 'Bio::MAGETAB::ControlledTerm',
                               clearer    => 'clear_technologyType',
                               predicate  => 'has_technologyType',
                               required   => 0 );

has 'surfaceType'         => ( is         => 'rw',
                               isa        => 'Bio::MAGETAB::ControlledTerm',
                               clearer    => 'clear_surfaceType',
                               predicate  => 'has_surfaceType',
                               required   => 0 );

has 'substrateType'       => ( is         => 'rw',
                               isa        => 'Bio::MAGETAB::ControlledTerm',
                               clearer    => 'clear_substrateType',
                               predicate  => 'has_substrateType',
                               required   => 0 );

has 'printingProtocol'    => ( is         => 'rw',
                               isa        => Str,
                               clearer    => 'clear_printingProtocol',
                               predicate  => 'has_printingProtocol',
                               required   => 0 );

has 'sequencePolymerType' => ( is         => 'rw',
                               isa        => 'Bio::MAGETAB::ControlledTerm',
                               clearer    => 'clear_sequencePolymerType',
                               predicate  => 'has_sequencePolymerType',
                               required   => 0 );

has 'designElements'      => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::DesignElement'],
                               auto_deref => 1,
                               clearer    => 'clear_designElements',
                               predicate  => 'has_designElements',
                               required   => 0 );

has 'comments'            => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::Comment'],
                               auto_deref => 1,
                               clearer    => 'clear_comments',
                               predicate  => 'has_comments',
                               required   => 0 );

__PACKAGE__->meta->make_immutable();

no Moose;

=pod

=head1 NAME

Bio::MAGETAB::ArrayDesign - MAGE-TAB array design class

=head1 SYNOPSIS

 use Bio::MAGETAB::ArrayDesign;

=head1 DESCRIPTION

This class is used to store information about array designs in
MAGE-TAB. This class can represent information from an ADF, or a
reference to an array design in a database. See
the L<DatabaseEntry|Bio::MAGETAB::DatabaseEntry> class for superclass methods.

=head1 ATTRIBUTES

=over 2

=item name (required)

The name of the array design (data type: String).

=item version (optional)

The version of the array design (data type: String).

=item uri (optional)

A URI for the array design (data type: Uri).

=item provider (optional)

The provider (typically the manufacturer) of the array design (data
type: String).

=item technologyType (optional)

The technology type of the array (data type:
Bio::MAGETAB::ControlledTerm).

=item surfaceType (optional)

The surface type of the array (data type:
Bio::MAGETAB::ControlledTerm).

=item substrateType (optional)

The substrate type of the array (data type:
Bio::MAGETAB::ControlledTerm).

=item printingProtocol (optional)

The protocol used for printing the array (data type: String).

=item sequencePolymerType (optional)

The sequence polymer type of the array (data type:
Bio::MAGETAB::ControlledTerm).

=item designElements (optional)

A list of array design elements (Features, Reporters and
CompositeElements) describing the array (data type:
Bio::MAGETAB::DesignElement).

=item comments (optional)

A list of user-defined comments for the array design (data type:
Bio::MAGETAB::Comment).

=back

=head1 METHODS

Each attribute has accessor (get_*) and mutator (set_*) methods, and
also predicate (has_*) and clearer (clear_*) methods where the
attribute is optional. Where an attribute represents a one-to-many
relationship the mutator accepts an arrayref and the accessor returns
an array.

=head1 SEE ALSO

L<Bio::MAGETAB::DatabaseEntry>

=head1 AUTHOR

Tim F. Rayner <tfrayner@gmail.com>

=head1 LICENSE

This library is released under version 2 of the GNU General Public
License (GPL).

=cut

1;
