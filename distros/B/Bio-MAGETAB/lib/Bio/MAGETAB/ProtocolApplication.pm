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
# $Id: ProtocolApplication.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::ProtocolApplication;

use Moose;
use MooseX::FollowPBP;

use MooseX::Types::Moose qw( ArrayRef );
use Bio::MAGETAB::Types qw( Date );

BEGIN { extends 'Bio::MAGETAB::BaseClass' };

has 'protocol'            => ( is         => 'rw',
                               isa        => 'Bio::MAGETAB::Protocol',
                               required   => 1 );

has 'parameterValues'     => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::ParameterValue'],
                               auto_deref => 1,
                               clearer    => 'clear_parameterValues',
                               predicate  => 'has_parameterValues',
                               required   => 0 );

has 'performers'          => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::Contact'],
                               auto_deref => 1,
                               clearer    => 'clear_performers',
                               predicate  => 'has_performers',
                               required   => 0 );

has 'comments'            => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::Comment'],
                               auto_deref => 1,
                               clearer    => 'clear_comments',
                               predicate  => 'has_comments',
                               required   => 0 );

has 'date'                => ( is         => 'rw',
                               isa        => Date,
                               clearer    => 'clear_date',
                               predicate  => 'has_date',
                               coerce     => 1,
                               required   => 0 );

__PACKAGE__->meta->make_immutable();

no Moose;

=pod

=head1 NAME

Bio::MAGETAB::ProtocolApplication - MAGE-TAB protocol application class

=head1 SYNOPSIS

 use Bio::MAGETAB::ProtocolApplication;

=head1 DESCRIPTION

This class is used to describe the actual application of experimental
protocols in the MAGE-TAB SDRF. See the L<BaseClass|Bio::MAGETAB::BaseClass> class for
superclass methods.

=head1 ATTRIBUTES

=over 2

=item protocol (required)

The protocol being applied (data type: Bio::MAGETAB::Protocol).

=item parameterValues (optional)

A list of parameter values used in this protocol application (data
type: Bio::MAGETAB::ParameterValue).

=item performers (optional)

A list of people who performed the protocol application (data type:
Bio::MAGETAB::Contact).

=item date (optional)

The date on which the protocol application was performed (data type:
Date).

=item comments (optional)

A list of user-defined comments on the protocol application (data
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
