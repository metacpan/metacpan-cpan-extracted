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
# $Id: Reporter.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::Reporter;

use Moose;
use MooseX::FollowPBP;

use MooseX::Types::Moose qw( Str ArrayRef );

BEGIN { extends 'Bio::MAGETAB::DesignElement' };

has 'name'                => ( is         => 'rw',
                               isa        => Str,
                               required   => 1 );

has 'sequence'            => ( is         => 'rw',
                               isa        => Str,
                               clearer    => 'clear_sequence',
                               predicate  => 'has_sequence',
                               required   => 0 );

has 'compositeElements'   => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::CompositeElement'],
                               auto_deref => 1,
                               clearer    => 'clear_compositeElements',
                               predicate  => 'has_compositeElements',
                               required   => 0 );

has 'databaseEntries'     => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::DatabaseEntry'],
                               auto_deref => 1,
                               clearer    => 'clear_databaseEntries',
                               predicate  => 'has_databaseEntries',
                               required   => 0 );

has 'controlType'         => ( is         => 'rw',
                               isa        => 'Bio::MAGETAB::ControlledTerm',
                               clearer    => 'clear_controlType',
                               predicate  => 'has_controlType',
                               required   => 0 );

has 'groups'              => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::ControlledTerm'],
                               auto_deref => 1,
                               clearer    => 'clear_groups',
                               predicate  => 'has_groups',
                               required   => 0 );

__PACKAGE__->meta->make_immutable();

no Moose;

=pod

=head1 NAME

Bio::MAGETAB::Reporter - MAGE-TAB reporter class

=head1 SYNOPSIS

 use Bio::MAGETAB::Reporter;

=head1 DESCRIPTION

This class is used to store information on array reporter elements in
MAGE-TAB. These elements typically correspond to probe sequences, or
in simple cases they may map directly to biologically interesting
sequences (e.g., genes). See the L<DesignElement|Bio::MAGETAB::DesignElement> class for
superclass methods.

=head1 ATTRIBUTES

=over 2

=item name (required)

The name of the reporter (data type: String).

=item sequence (optional)

The actual reporter sequence (usually DNA; data type: String).

=item compositeElements (optional)

A list of CompositeElements composed wholly or in part of this
reporter (data type: Bio::MAGETAB::CompositeElement).

=item databaseEntries (optional)

A list of database entries for the reporter sequence (data type:
Bio::MAGETAB::DatabaseEntry).

=item controlType (optional)

Where the reporter describes a control probe, this attribute should be
used to give its type (e.g., 'control_buffer'; data type:
Bio::MAGETAB::ControlledTerm).

=item groups (optional)

A list of arbitrary groups to which the reporter belongs. Typically
these groups may describe which probes are experimental and which are
controls; another use might be to indicate the source species of a
probe on a multi-species array design (data type:
Bio::MAGETAB::ControlledTerm).

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
