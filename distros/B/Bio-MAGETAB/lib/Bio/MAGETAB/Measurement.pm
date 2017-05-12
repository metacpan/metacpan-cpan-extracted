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
# $Id: Measurement.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::Measurement;

use Moose;
use MooseX::FollowPBP;

use MooseX::Types::Moose qw( Str );

BEGIN { extends 'Bio::MAGETAB::BaseClass' };

has 'measurementType'     => ( is         => 'rw',
                               isa        => Str,
                               required   => 1 );

has 'value'               => ( is         => 'rw',
                               isa        => Str,
                               clearer    => 'clear_value',
                               predicate  => 'has_value',
                               required   => 0 );

has 'minValue'            => ( is         => 'rw',
                               isa        => Str,
                               clearer    => 'clear_minValue',
                               predicate  => 'has_minValue',
                               required   => 0 );

has 'maxValue'            => ( is         => 'rw',
                               isa        => Str,
                               clearer    => 'clear_maxValue',
                               predicate  => 'has_maxValue',
                               required   => 0 );

has 'unit'                => ( is         => 'rw',
                               isa        => 'Bio::MAGETAB::ControlledTerm',
                               clearer    => 'clear_unit',
                               predicate  => 'has_unit',
                               required   => 0 );

__PACKAGE__->meta->make_immutable();

no Moose;

=pod

=head1 NAME

Bio::MAGETAB::Measurement - MAGE-TAB measurement class

=head1 SYNOPSIS

 use Bio::MAGETAB::Measurement;

=head1 DESCRIPTION

This class is used to describe measurements in MAGE-TAB. It can
describe individual values, or ranges of values, associated with an
optional unit. See the L<BaseClass|Bio::MAGETAB::BaseClass> class for superclass methods.

=head1 ATTRIBUTES

=over 2

=item measurementType (required)

The type of measurement (i.e., the quantity being measured). This is
equivalent to the ControlledTerm 'category' attribute (data type:
String).

=item value (optional)

A single value for the measurement. If a range of values is being
described this attribute should be left unset, and minValue and
maxValue used instead (data type: String).

=item minValue (optional)

The lower end of a range of values for the measurement. If a single
value is being specified, just use 'value' instead (data type:
String).

=item maxValue (optional)

The upper end of a range of values for the measurement. If a single
value is being specified, just use 'value' instead (data type:
String).

=item unit (optional)

The unit of the measurement (data type: Bio::MAGETAB::ControlledTerm).

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
