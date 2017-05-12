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
# $Id: ControlledTerm.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::ControlledTerm;

use Moose;
use MooseX::FollowPBP;

use MooseX::Types::Moose qw( Str );

BEGIN { extends 'Bio::MAGETAB::DatabaseEntry' };

has 'value'               => ( is         => 'rw',
                               isa        => Str,
                               required   => 1 );

has 'category'            => ( is         => 'rw',
                               isa        => Str,
                               required   => 1 );

__PACKAGE__->meta->make_immutable();

no Moose;

=pod

=head1 NAME

Bio::MAGETAB::ControlledTerm - MAGE-TAB controlled term class

=head1 SYNOPSIS

 use Bio::MAGETAB::ControlledTerm;

=head1 DESCRIPTION

This class is used to store information on controlled terms in
MAGE-TAB. These will often (but not always) be terms from an ontology,
in which case the source of these terms should also be given via the
parent class DatabaseEntry attributes. See
the L<DatabaseEntry|Bio::MAGETAB::DatabaseEntry> class for superclass methods.

=head1 ATTRIBUTES

=over 2

=item category (required)

A category to provide context for the term (data type: String).

=item value (required)

The term value itself (data type: String).

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
