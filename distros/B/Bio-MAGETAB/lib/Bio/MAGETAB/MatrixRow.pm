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
# $Id: MatrixRow.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::MatrixRow;

use Moose;
use MooseX::FollowPBP;

use MooseX::Types::Moose qw( Int );

BEGIN { extends 'Bio::MAGETAB::BaseClass' };

has 'rowNumber'           => ( is         => 'rw',
                               isa        => Int,
                               required   => 1 );

has 'designElement'       => ( is         => 'rw',
                               isa        => 'Bio::MAGETAB::DesignElement',
                               required   => 1 );

__PACKAGE__->meta->make_immutable();

no Moose;

=pod

=head1 NAME

Bio::MAGETAB::MatrixRow - MAGE-TAB matrix row class

=head1 SYNOPSIS

 use Bio::MAGETAB::MatrixRow;

=head1 DESCRIPTION

This class is used to describe the rows of a MAGE-TAB data matrix. It
acts as a mapping between a numbered row in the matrix, and the design
element (Feature, Reporter or CompositeElement) to which it
applies. See the L<BaseClass|Bio::MAGETAB::BaseClass> class for superclass methods.

=head1 ATTRIBUTES

=over 2

=item rowNumber (required)

The number of the row in the data matrix. Rows are assumed to be
numbered from top to bottom, starting at one for the first data
row; however this is not constrained by the model and you may use
whatever local conventions you prefer (data type: Integer).

=item designElement (required)

The DesignElement to which the data in this row applies (data type:
Bio::MAGETAB::DesignElement).

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
