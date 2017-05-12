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
# $Id: MatrixColumn.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::MatrixColumn;

use Moose;
use MooseX::FollowPBP;

use MooseX::Types::Moose qw( Int ArrayRef );

BEGIN { extends 'Bio::MAGETAB::BaseClass' };

has 'columnNumber'        => ( is         => 'rw',
                               isa        => Int,
                               required   => 1 );

has 'quantitationType'    => ( is         => 'rw',
                               isa        => 'Bio::MAGETAB::ControlledTerm',
                               required   => 1 );

has 'referencedNodes'     => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::Node'],
                               auto_deref => 1,
                               required   => 1 );

__PACKAGE__->meta->make_immutable();

no Moose;

=pod

=head1 NAME

Bio::MAGETAB::MatrixColumn - MAGE-TAB matrix column class

=head1 SYNOPSIS

 use Bio::MAGETAB::MatrixColumn;

=head1 DESCRIPTION

This class is used to describe the columns of a MAGE-TAB data
matrix. It acts as a mapping between a numbered column in the matrix,
the quantitation type of that column, and the SDRF node or nodes to
which it applies. See the L<BaseClass|Bio::MAGETAB::BaseClass> class for superclass
methods.

=head1 ATTRIBUTES

=over 2

=item columnNumber (required)

The number of the column in the data matrix. Columns are assumed to be
numbered from left to right, starting at one for the first data
column; however this is not constrained by the model and you may use
whatever local conventions you prefer (data type: Integer).

=item quantitationType (required)

The quantitation type of the data contained in the column (data type:
Bio::MAGETAB::ControlledTerm).

=item referencedNodes (required)

A list of Nodes from the SDRF to which the data in this column applies
(data type: Bio::MAGETAB::Node).

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
