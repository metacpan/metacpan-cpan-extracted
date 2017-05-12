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
# $Id: DataAcquisition.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::DataAcquisition;

use Moose;
use MooseX::FollowPBP;

BEGIN { extends 'Bio::MAGETAB::Event' };

__PACKAGE__->meta->make_immutable();

no Moose;

=pod

=head1 NAME

Bio::MAGETAB::DataAcquisition - MAGE-TAB data acquisition class

=head1 SYNOPSIS

 use Bio::MAGETAB::DataAcquisition;

=head1 DESCRIPTION

This class represents events which generate data files, such as the
scanning of a hybridized microarray slide. See the L<Event|Bio::MAGETAB::Event> class
for superclass methods.

=head1 ATTRIBUTES

No class-specific attributes. See L<Bio::MAGETAB::Event>.

=head1 METHODS

No class-specific methods. See L<Bio::MAGETAB::Event>.

=head1 SEE ALSO

L<Bio::MAGETAB::Event>

=head1 AUTHOR

Tim F. Rayner <tfrayner@gmail.com>

=head1 LICENSE

This library is released under version 2 of the GNU General Public
License (GPL).

=cut

1;
