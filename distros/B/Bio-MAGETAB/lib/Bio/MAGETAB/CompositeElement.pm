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
# $Id: CompositeElement.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::CompositeElement;

use Moose;
use MooseX::FollowPBP;

use MooseX::Types::Moose qw( Str ArrayRef );

BEGIN { extends 'Bio::MAGETAB::DesignElement' };

has 'name'                => ( is       => 'rw',
                               isa      => Str,
                               required => 1 );

has 'databaseEntries'     => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::DatabaseEntry'],
                               auto_deref => 1,
                               clearer    => 'clear_databaseEntries',
                               predicate  => 'has_databaseEntries',
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

Bio::MAGETAB::CompositeElement - MAGE-TAB composite element class

=head1 SYNOPSIS

 use Bio::MAGETAB::CompositeElement;

=head1 DESCRIPTION

This class is used to store information on composite elements in
MAGE-TAB. These elements typically correspond to biologically relevant
sequences or features (e.g., genes, exons, etc.). See
the L<DesignElement|Bio::MAGETAB::DesignElement> class for superclass methods.

=head1 ATTRIBUTES

=over 2

=item name (required)

The name of the composite element (data type: String).

=item databaseEntries (optional)

A list of database entries for the composite element (data type:
Bio::MAGETAB::DatabaseEntry).

=item comments (optional)

A list of user-defined comments for the element (data type:
Bio::MAGETAB::Comment).

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
