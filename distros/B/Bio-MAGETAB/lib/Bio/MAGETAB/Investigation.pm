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
# $Id: Investigation.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::Investigation;

use Moose;
use MooseX::FollowPBP;

use MooseX::Types::Moose qw( Str ArrayRef );
use Bio::MAGETAB::Types qw( Date );

BEGIN { extends 'Bio::MAGETAB::BaseClass' };

has 'title'               => ( is         => 'rw',
                               isa        => Str,
                               required   => 1 );

has 'description'         => ( is         => 'rw',
                               isa        => Str,
                               clearer    => 'clear_description',
                               predicate  => 'has_description',
                               required   => 0 );

has 'date'                => ( is         => 'rw',
                               isa        => Date,
                               clearer    => 'clear_date',
                               predicate  => 'has_date',
                               coerce     => 1,
                               required   => 0 );

has 'publicReleaseDate'   => ( is         => 'rw',
                               isa        => Date,
                               clearer    => 'clear_publicReleaseDate',
                               predicate  => 'has_publicReleaseDate',
                               coerce     => 1,
                               required   => 0 );

has 'contacts'            => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::Contact'],
                               auto_deref => 1,
                               clearer    => 'clear_contacts',
                               predicate  => 'has_contacts',
                               required   => 0 );

has 'factors'             => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::Factor'],
                               auto_deref => 1,
                               clearer    => 'clear_factors',
                               predicate  => 'has_factors',
                               required   => 0 );

has 'sdrfs'               => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::SDRF'],
                               auto_deref => 1,
                               clearer    => 'clear_sdrfs',
                               predicate  => 'has_sdrfs',
                               required   => 0 );

has 'protocols'           => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::Protocol'],
                               auto_deref => 1,
                               clearer    => 'clear_protocols',
                               predicate  => 'has_protocols',
                               required   => 0 );

has 'publications'        => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::Publication'],
                               auto_deref => 1,
                               clearer    => 'clear_publications',
                               predicate  => 'has_publications',
                               required   => 0 );

has 'termSources'         => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::TermSource'],
                               auto_deref => 1,
                               clearer    => 'clear_termSources',
                               predicate  => 'has_termSources',
                               required   => 0 );

has 'designTypes'         => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::ControlledTerm'],
                               auto_deref => 1,
                               clearer    => 'clear_designTypes',
                               predicate  => 'has_designTypes',
                               required   => 0 );

has 'normalizationTypes'  => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::ControlledTerm'],
                               auto_deref => 1,
                               clearer    => 'clear_normalizationTypes',
                               predicate  => 'has_normalizationTypes',
                               required   => 0 );

has 'replicateTypes'      => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::ControlledTerm'],
                               auto_deref => 1,
                               clearer    => 'clear_replicateTypes',
                               predicate  => 'has_replicateTypes',
                               required   => 0 );

has 'qualityControlTypes' => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::ControlledTerm'],
                               auto_deref => 1,
                               clearer    => 'clear_qualityControlTypes',
                               predicate  => 'has_qualityControlTypes',
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

Bio::MAGETAB::Investigation - MAGE-TAB investigation class

=head1 SYNOPSIS

 use Bio::MAGETAB::Investigation;

=head1 DESCRIPTION

This class is used to store top-level information on the investigation
in MAGE-TAB. This class also acts as a container for the information
in an IDF file. See the L<BaseClass|Bio::MAGETAB::BaseClass> class for superclass methods.

=head1 ATTRIBUTES

=over 2

=item title (required)

The title of the investigation (data type: String).

=item description (optional)

A free-text description of the investigation (data type: String).

=item date (optional)

The date on which the investigation was performed (data type: Date).

=item publicReleaseDate (optional)

The date on which the experimental data was, or will be, publicly
released (data type: Date).

=item contacts (optional)

A list of contacts for the investigation (data type:
Bio::MAGETAB::Contact).

=item factors (optional)

A list of experimental factors (variables) studied during the
investigation (data type: Bio::MAGETAB::Factor).

=item sdrfs (optional)

A list of SDRFs associated with the investigation (data type:
Bio::MAGETAB::SDRF).

=item protocols (optional)

A list of experimental protocols used in the investigation (data type:
Bio::MAGETAB::Protocol)

=item publications (optional)

A list of publications related to the investigation (data type:
Bio::MAGETAB::Publication).

=item termSources (optional)

A list of term sources (usually databases and/or ontologies) used to
annotate the investigation (data type: Bio::MAGETAB::TermSource).

=item designTypes (optional)

A list of experiment design types, typically taken from a suitable
ontology (data type: Bio::MAGETAB::ControlledTerm).

=item normalizationTypes (optional)

A list of experiment data normalization types (data type:
Bio::MAGETAB::ControlledTerm).

=item replicateTypes (optional)

A list of replicate types for the experiment (typically specifying
technical and/or biological replicates; date type:
Bio::MAGETAB::ControlledTerm).

=item qualityControlTypes (optional)

A list of quality control terms describing the experiment (data type:
Bio::MAGETAB::ControlledTerm).

=item comments (optional)

A list of user-defined comments attached to the investigation (data
type: Bio::MAGETAB::Comment).

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
