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
# $Id: Feature.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::Feature;

use Moose;
use MooseX::FollowPBP;

use MooseX::Types::Moose qw( Int );

BEGIN { extends 'Bio::MAGETAB::DesignElement' };

has 'blockCol'            => ( is       => 'rw',
                               isa      => Int,
                               required => 1 );

has 'blockRow'            => ( is       => 'rw',
                               isa      => Int,
                               required => 1 );

has 'col'                 => ( is       => 'rw',
                               isa      => Int,
                               required => 1 );

has 'row'                 => ( is       => 'rw',
                               isa      => Int,
                               required => 1 );

has 'reporter'            => ( is         => 'rw',
                               isa        => 'Bio::MAGETAB::Reporter',
                               required   => 1 );

__PACKAGE__->meta->make_immutable();

no Moose;

=pod

=head1 NAME

Bio::MAGETAB::Feature - MAGE-TAB feature class

=head1 SYNOPSIS

 use Bio::MAGETAB::Feature;

=head1 DESCRIPTION

This class is used to store information on array features in
MAGE-TAB. These elements will correspond to the individual spots on
the array. See the L<DesignElement|Bio::MAGETAB::DesignElement> class for superclass methods.

=head1 ATTRIBUTES

=over 2

=item blockCol (required)

The block column number of the feature (data type: Integer).

=item blockRow (required)

The block row number of the feature (data type: Integer).

=item col (required)

The number of the feature's column within the enclosing block (data
type: Integer).

=item row (required)

The number of the feature's row within the enclosing block (data
type: Integer).

=item reporter (required)

The reporter with which this feature is associated (data type:
Bio::MAGETAB::Reporter).

=back

=head1 METHODS

Each attribute has accessor (get_*) and mutator (set_*) methods, and
also predicate (has_*) and clearer (clear_*) methods where the
attribute is optional. Where an attribute represents a one-to-many
relationship the mutator accepts an arrayref and the accessor returns
an array.

=head1 SEE ALSO

L<Bio::MAGETAB::DesignElement>

=head1 AUTHOR

Tim F. Rayner <tfrayner@gmail.com>

=head1 LICENSE

This library is released under version 2 of the GNU General Public
License (GPL).

=cut

1;
