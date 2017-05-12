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
# $Id: DatabaseEntry.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::DatabaseEntry;

use Moose;
use MooseX::FollowPBP;

use MooseX::Types::Moose qw( Str );

BEGIN { extends 'Bio::MAGETAB::BaseClass' };

has 'accession'           => ( is         => 'rw',
                               isa        => Str,
                               clearer    => 'clear_accession',
                               predicate  => 'has_accession',
                               required   => 0 );

has 'termSource'          => ( is         => 'rw',
                               isa        => 'Bio::MAGETAB::TermSource',
                               clearer    => 'clear_termSource',
                               predicate  => 'has_termSource',
                               required   => 0 );

__PACKAGE__->meta->make_immutable();

no Moose;

=pod

=head1 NAME

Bio::MAGETAB::DatabaseEntry - MAGE-TAB database entry class

=head1 SYNOPSIS

 use Bio::MAGETAB::DatabaseEntry;

=head1 DESCRIPTION

This class is used to store MAGE-TAB database entry information. These
entries can be from sequence databases (e.g. as attached to
Reporters), ontologies (when using the ControlledTerm subclass), or
databases which hold higher-level metadata (e.g. ArrayDesigns,
Protocols). See the L<BaseClass|Bio::MAGETAB::BaseClass> class for superclass methods.

=head1 ATTRIBUTES

=over 2

=item accession (optional)

The accession number for the database entry (data type: String).

=item termSource (optional)

The TermSource (e.g., database or ontology) which defines the entry,
and which recognises the given accession (data type:
Bio::MAGETAB::TermSource).

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
