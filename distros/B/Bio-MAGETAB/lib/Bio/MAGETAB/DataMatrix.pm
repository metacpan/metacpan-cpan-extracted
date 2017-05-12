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
# $Id: DataMatrix.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::DataMatrix;

use Moose;
use MooseX::FollowPBP;

use MooseX::Types::Moose qw( Str ArrayRef );

BEGIN { extends 'Bio::MAGETAB::Data' };

# FIXME consider dropping rowIdentifierType; it's redundant.
has 'rowIdentifierType'   => ( is         => 'rw',
                               isa        => Str,
                               clearer    => 'clear_rowIdentifierType',
                               predicate  => 'has_rowIdentifierType',
                               required   => 0 );

has 'matrixColumns'       => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::MatrixColumn'],
                               clearer    => 'clear_matrixColumns',
                               predicate  => 'has_matrixColumns',
                               auto_deref => 1,
                               required   => 0 );

has 'matrixRows'          => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::MatrixRow'],
                               clearer    => 'clear_matrixRows',
                               predicate  => 'has_matrixRows',
                               auto_deref => 1,
                               required   => 0 );

__PACKAGE__->meta->make_immutable();

no Moose;

=pod

=head1 NAME

Bio::MAGETAB::DataMatrix - MAGE-TAB data matrix class

=head1 SYNOPSIS

 use Bio::MAGETAB::DataMatrix;

=head1 DESCRIPTION

This class describes a particular type of data file known as a data
matrix. The format of these data matrices is precisely defined, such
that columns represent quantitation types applied to nodes of interest
within the SDRF (e.g. scanned intensity values), and rows represent
design elements (e.g. probes). See the L<Data|Bio::MAGETAB::Data> class for
superclass methods, the L<DataFile|Bio::MAGETAB::DataFile> class for the generic data
file class, and the MAGE-TAB specification for more information on
data matrices.

=head1 ATTRIBUTES

=over 2

=item rowIdentifierType (optional)

The type of identifier used for each matrix row. This will typically
be Reporter, Composite Element, Term Source or Coordinate. This is
primarily used to record whatever is claimed by the original data
matrix file heading, which may be used to validate the matrixRow
DesignElements subsequent to the parsing step. However, given that
this is redundant information this attribute may be dropped in a later
version of the model (data type: String).

=item matrixColumns (optional)

A list of MatrixColumn objects which map the columns of the data
matrix to quantitation types and SDRF nodes. Note that this list may
be unordered, and that the MatrixColumn objects themselves have a
columnNumber attribute which defines column ordering (data type:
Bio::MAGETAB::MatrixColumn).

=item matrixRows (optional)

A list of MatrixRow objects which map the rows of the data matrix to
design elements. Note that this list may be unordered, and that the
MatrixRow objects themselves have a rowNumber attribute which defines
row ordering (data type: Bio::MAGETAB::MatrixRow).

=back

=head1 METHODS

Each attribute has accessor (get_*) and mutator (set_*) methods, and
also predicate (has_*) and clearer (clear_*) methods where the
attribute is optional. Where an attribute represents a one-to-many
relationship the mutator accepts an arrayref and the accessor returns
an array.

=head1 SEE ALSO

L<Bio::MAGETAB::Data>

=head1 AUTHOR

Tim F. Rayner <tfrayner@gmail.com>

=head1 LICENSE

This library is released under version 2 of the GNU General Public
License (GPL).

=cut

1;
