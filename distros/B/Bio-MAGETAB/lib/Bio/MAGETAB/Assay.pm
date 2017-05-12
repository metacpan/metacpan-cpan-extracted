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
# $Id: Assay.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::Assay;

use Moose;
use MooseX::FollowPBP;

BEGIN { extends 'Bio::MAGETAB::Event' };

has 'arrayDesign'         => ( is         => 'rw',
                               isa        => 'Bio::MAGETAB::ArrayDesign',
                               clearer    => 'clear_arrayDesign',
                               predicate  => 'has_arrayDesign',
                               required   => 0 );

has 'technologyType'      => ( is         => 'rw',
                               isa        => 'Bio::MAGETAB::ControlledTerm',
                               required   => 1 );

__PACKAGE__->meta->make_immutable();

no Moose;

=pod

=head1 NAME

Bio::MAGETAB::Assay - MAGE-TAB assay class

=head1 SYNOPSIS

 use Bio::MAGETAB::Assay;

=head1 DESCRIPTION

This class is used to store information about assays in MAGE-TAB. This
is a generic class which can represent any assay type, specified via
its technologyType attribute. Assays which specifically represent
hybridization events should use a 'hybridization' ControlledTerm as
their technologyType and should also link to an ArrayDesign. See
the L<Event|Bio::MAGETAB::Event> class for superclass methods.

=head1 ATTRIBUTES

=over 2

=item technologyType (required)

The type of assay that was performed (hybridization, rtPCR, etc.; data
type: Bio::MAGETAB::ControlledTerm).

=item arrayDesign (optional)

The array design associated with the assay. Typically this will only
be used for hybridization Assays (data type:
Bio::MAGETAB::ArrayDesign)

=back

=head1 METHODS

Each attribute has accessor (get_*) and mutator (set_*) methods, and
also predicate (has_*) and clearer (clear_*) methods where the
attribute is optional. Where an attribute represents a one-to-many
relationship the mutator accepts an arrayref and the accessor returns
an array.

=head1 SEE ALSO

L<Bio::MAGETAB::Event>

=head1 AUTHOR

Tim F. Rayner <tfrayner@gmail.com>

=head1 LICENSE

This library is released under version 2 of the GNU General Public
License (GPL).

=cut

1;
