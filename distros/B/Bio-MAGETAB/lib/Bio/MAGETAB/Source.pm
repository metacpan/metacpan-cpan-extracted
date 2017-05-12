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
# $Id: Source.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::Source;

use Moose;
use MooseX::FollowPBP;

use MooseX::Types::Moose qw( ArrayRef );

BEGIN { extends 'Bio::MAGETAB::Material' };

has 'providers'           => ( is         => 'rw',
                               isa        => ArrayRef['Bio::MAGETAB::Contact'],
                               auto_deref => 1,
                               clearer    => 'clear_providers',
                               predicate  => 'has_providers',
                               required   => 0 );

__PACKAGE__->meta->make_immutable();

no Moose;

=pod

=head1 NAME

Bio::MAGETAB::Source - MAGE-TAB source class

=head1 SYNOPSIS

 use Bio::MAGETAB::Source;

=head1 DESCRIPTION

This class is used to store information on the starting biological
material for a given experiment ('source'). These nodes typically form
the starting point for the experimental design
graph. See the L<Material|Bio::MAGETAB::Material> class for superclass methods.

=head1 ATTRIBUTES

=over 2

=item providers (optional)

A list of names of providers of the source material (data type:
Bio::MAGETAB::Contact).

=back

=head1 METHODS

Each attribute has accessor (get_*) and mutator (set_*) methods, and
also predicate (has_*) and clearer (clear_*) methods where the
attribute is optional. Where an attribute represents a one-to-many
relationship the mutator accepts an arrayref and the accessor returns
an array.

=head1 SEE ALSO

L<Bio::MAGETAB::Material>

=head1 AUTHOR

Tim F. Rayner <tfrayner@gmail.com>

=head1 LICENSE

This library is released under version 2 of the GNU General Public
License (GPL).

=cut

1;
