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
# $Id: Publication.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::Publication;

use Moose;
use MooseX::FollowPBP;

use MooseX::Types::Moose qw( Str );

BEGIN { extends 'Bio::MAGETAB::BaseClass' };

has 'title'               => ( is         => 'rw',
                               isa        => Str,
                               required   => 1 );

has 'authorList'          => ( is         => 'rw',
                               isa        => Str,
                               clearer    => 'clear_authorList',
                               predicate  => 'has_authorList',
                               required   => 0 );

has 'pubMedID'            => ( is         => 'rw',
                               isa        => Str,
                               clearer    => 'clear_pubMedID',
                               predicate  => 'has_pubMedID',
                               required   => 0 );

has 'DOI'                 => ( is         => 'rw',
                               isa        => Str,
                               clearer    => 'clear_DOI',
                               predicate  => 'has_DOI',
                               required   => 0 );

has 'status'              => ( is         => 'rw',
                               isa        => 'Bio::MAGETAB::ControlledTerm',
                               clearer    => 'clear_status',
                               predicate  => 'has_status',
                               required   => 0 );

__PACKAGE__->meta->make_immutable();

no Moose;

=pod

=head1 NAME

Bio::MAGETAB::Publication - MAGE-TAB publication class

=head1 SYNOPSIS

 use Bio::MAGETAB::Publication;

=head1 DESCRIPTION

This class is used to describe the publications listed in a MAGE-TAB
IDF file. See the L<BaseClass|Bio::MAGETAB::BaseClass> class for superclass methods.

=head1 ATTRIBUTES

=over 2

=item title (required)

The title of the publication (data type: String).

=item authorList (optional)

A simple listing of all the authors of the publication (data type:
String).

=item pubMedID (optional)

The PubMed ID (where available) of the publication (data type:
String).

=item DOI (optional)

The DOI (where available) of the publication (data type: String).

=item status (optional)

The status of the publication (e.g. 'submitted', 'in_press',
'published'), usually taken from a suitable ontology (data type:
Bio::MAGETAB::ControlledTerm).

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
