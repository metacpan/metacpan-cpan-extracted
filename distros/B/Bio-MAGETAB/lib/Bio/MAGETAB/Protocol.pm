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
# $Id: Protocol.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::Protocol;

use Moose;
use MooseX::FollowPBP;

use MooseX::Types::Moose qw( Str );

BEGIN { extends 'Bio::MAGETAB::DatabaseEntry' };

has 'name'                => ( is         => 'rw',
                               isa        => Str,
                               required   => 1 );

has 'text'                => ( is         => 'rw',
                               isa        => Str,
                               clearer    => 'clear_text',
                               predicate  => 'has_text',
                               required   => 0 );

has 'software'            => ( is         => 'rw',
                               isa        => Str,
                               clearer    => 'clear_software',
                               predicate  => 'has_software',
                               required   => 0 );

has 'hardware'            => ( is         => 'rw',
                               isa        => Str,
                               clearer    => 'clear_hardware',
                               predicate  => 'has_hardware',
                               required   => 0 );

has 'protocolType'        => ( is         => 'rw',
                               isa        => 'Bio::MAGETAB::ControlledTerm',
                               clearer    => 'clear_protocolType',
                               predicate  => 'has_protocolType',
                               required   => 0 );

has 'contact'             => ( is         => 'rw',
                               isa        => Str,
                               clearer    => 'clear_contact',
                               predicate  => 'has_contact',
                               required   => 0 );

__PACKAGE__->meta->make_immutable();

no Moose;

=pod

=head1 NAME

Bio::MAGETAB::Protocol - MAGE-TAB protocol class

=head1 SYNOPSIS

 use Bio::MAGETAB::Protocol;

=head1 DESCRIPTION

This class is used to describe experimental protocols in MAGE-TAB. It
can either contain all the information about a protocol itself, or it
can link to a protocol entry in a suitable database via its
superclass. See the L<DatabaseEntry|Bio::MAGETAB::DatabaseEntry> class for superclass methods.

=head1 ATTRIBUTES

=over 2

=item name (required)

The name of the protocol (data type: String).

=item text (optional)

A free-text description of the protocol, giving all the steps in the
procedure (data type: String).

=item software (optional)

The software used in the protocol. Multiple softwares must be
concatenated into a single value (data type: String).

=item hardware (optional)

The hardware used in the protocol. Multiple hardwares must be
concatenated into a single value (data type: String).

=item protocolType (optional)

The type of the protocol ('nucleic_acid_extraction','labeling' etc.;
data type: Bio::MAGETAB::ControlledTerm).

=item contact (optional)

A contact for more information on the protocol. Multiple contacts must
be concatenated into a single value (data type: String).

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
