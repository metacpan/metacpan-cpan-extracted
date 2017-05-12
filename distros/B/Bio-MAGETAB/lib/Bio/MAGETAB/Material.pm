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
# $Id: Material.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::Material;

use Moose;
use MooseX::FollowPBP;

use MooseX::Types::Moose qw( Str ArrayRef );

BEGIN { extends 'Bio::MAGETAB::Node'; };

# This is an abstract class; block direct instantiation.
sub BUILD {

    my ( $self, $params ) = @_;

    if ( blessed $self eq __PACKAGE__ ) {
        confess("ERROR: Attempt to instantiate abstract class " . __PACKAGE__);
    }

    return;
}

has 'name'                => ( is         => 'rw',
                               isa        => Str,
                               required   => 1 );

has 'materialType'        => ( is         => 'rw',
                               isa        => 'Bio::MAGETAB::ControlledTerm',
                               clearer    => 'clear_materialType',
                               predicate  => 'has_materialType',
                               required   => 0 );

has 'description'         => ( is         => 'rw',
                               isa        => Str,
                               clearer    => 'clear_description',
                               predicate  => 'has_description',
                               required   => 0 );

has 'characteristics'     => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::ControlledTerm'],
                               auto_deref => 1,
                               clearer    => 'clear_characteristics',
                               predicate  => 'has_characteristics',
                               required   => 0 );

has 'measurements'        => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::Measurement'],
                               auto_deref => 1,
                               clearer    => 'clear_measurements',
                               predicate  => 'has_measurements',
                               required   => 0 );

__PACKAGE__->meta->make_immutable();

no Moose;

=pod

=head1 NAME

Bio::MAGETAB::Material - Abstract material class

=head1 SYNOPSIS

 use Bio::MAGETAB::Material;

=head1 DESCRIPTION

This class is an abstract class from which all MAGE-TAB Material
classes (Source, Sample, Extract, LabeledExtract) are derived. It
cannot be instantiated directly. See the L<Node|Bio::MAGETAB::Node> class for
superclass methods.

=head1 ATTRIBUTES

=over 2

=item name (required)

The name of the material (data type: String).

=item materialType (optional)

The type of the material (e.g. 'whole_organism', 'organism_part',
'RNA' etc.), usually from a suitable ontology (data type:
Bio::MAGETAB::ControlledTerm).

=item description (optional)

A free-text description of the material. In general the use of this
attribute is discouraged due to the difficulty of computationally
parsing natural languages (data type: String).

=item characteristics (optional)

A list of characteristics of the material. These may describe any
aspect of the material, and should ideally be taken from an
appropriate ontology (data type: Bio::MAGETAB::ControlledTerm).

=item measurements (optional)

A list of measurements of the material. These may describe any
measurable property of the material. Units are handled by the
Measurement class (data type: Bio::MAGETAB::Measurement).

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
