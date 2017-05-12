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
# $Id: FactorValue.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::FactorValue;

use Moose;
use MooseX::FollowPBP;

BEGIN { extends 'Bio::MAGETAB::BaseClass' };

has 'measurement'         => ( is         => 'rw',
                               isa        => 'Bio::MAGETAB::Measurement',
                               clearer    => 'clear_measurement',
                               predicate  => 'has_measurement',
                               required   => 0 );

has 'term'                => ( is         => 'rw',
                               isa        => 'Bio::MAGETAB::ControlledTerm',
                               clearer    => 'clear_term',
                               predicate  => 'has_term',
                               required   => 0 );

has 'factor'              => ( is         => 'rw',
                               isa        => 'Bio::MAGETAB::Factor',
                               required   => 1 );

__PACKAGE__->meta->make_immutable();

no Moose;

=pod

=head1 NAME

Bio::MAGETAB::FactorValue - MAGE-TAB experimental factor class

=head1 SYNOPSIS

 use Bio::MAGETAB::FactorValue;

=head1 DESCRIPTION

This class is used to store the values of the factors investigated by
the experiment. This class links the Factor objects to Measurements or
ControlledTerms describing the variables applying to each line of the
SDRF. Either the measurement or term attribute should be used, but not
both. See the L<BaseClass|Bio::MAGETAB::BaseClass> class for superclass methods.

=head1 ATTRIBUTES

=over 2

=item measurement (optional)

A measurement of the given Factor variable (data type:
Bio::MAGETAB::Measurement).

=item term (optional)

A controlled term giving the value of the Factor (data type:
Bio::MAGETAB::ControlledTerm).

=item factor (required)

The Factor to which this particular factor value applies (data type:
Bio::MAGETAB::Factor).

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
