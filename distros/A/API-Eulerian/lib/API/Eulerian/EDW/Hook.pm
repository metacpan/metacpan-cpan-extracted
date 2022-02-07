#/usr/bin/env perl
###############################################################################
#
# @file Hook.pm
#
# @brief Eulerian Data Warehouse Peer Hook Base class Module definition.
#
# This module is aimed to provide callback hooks userfull to process reply data.
# Library user can create is own Hook class conforming to this module interface
# to handle reply data in specific manner.
#
# @author Thorillon Xavier:x.thorillon@eulerian.com
#
# @date 26/11/2021
#
# @version 1.0
#
###############################################################################
#
# Setup module name
#
package API::Eulerian::EDW::Hook;
#
# Enforce compilor rules
#
use strict; use warnings;
#
# @brief Allocate a new Eulerian Data Warehouse Peer Hook.
#
# @param $class - Eulerian Data Warehouse Peer Hook Class.
# @param $setup - Setup attributes.
#
# @return Eulerian Data Warehouse Peer Hook instance.
#
sub new
{
  my ( $class, $setup ) = @_;
  my $self = bless( {}, $class );
  $self->setup( $setup );
  return $self;
}
#
# @brief Setup Eulerian Data Warehouse Peer Hook.
#
# @param $self - Eulerian Data Warehouse Peer Hook.
# @param $setup - Setup entries.
#
sub setup
{
  my ( $self, $setup ) = @_;
}
#
# @brief
#
# @param $self - Eulerian Data Warehouse Peer Hook.
# @param $uuid - UUID of Eulerian Analytics Analysis.
# @param $start - Timerange begin.
# @param $end - Timerange end.
# @param $columns - Array of Columns definitions.
#
sub on_headers
{
  my ( $self, $uuid, $start, $end, $columns ) = @_;
}
#
# @brief
#
# @param $self - Eulerian Data Warehouse Peer Hook.
# @param $uuid - UUID of Eulerian Analytics Analysis.
# @param $rows - Array of Array of Columns values.
#
sub on_add
{
  my ( $self, $uuid, $rows ) = @_;
}
#
# @brief
#
# @param $self - Eulerian Data Warehouse Peer Hook.
# @param $uuid - UUID of Eulerian Analytics Analysis.
# @param $rows - Array of Array of Columns values.
#
sub on_replace
{
  my ( $self, $uuid, $rows ) = @_;
}
#
# @brief
#
# @param $self - Eulerian Data Warehouse Peer Hook.
# @param $uuid - UUID of Eulerian Analytics Analysis.
# @param $progress - Progression value.
#
sub on_progress
{
  my ( $self, $uuid, $progress ) = @_;
}
#
# @brief
#
# @param $self - Eulerian Data Warehouse Peer Hook.
# @param $uuid - UUID of Eulerian Analytics Analysis.
# @param $token - AES Token or Bearer.
# @param $errnum - Error number.
# @param $err - Error description.
# @param $updated - Count of updates on server.
#
sub on_status
{
  my ( $self, $uuid, $token, $errnum, $err, $updated ) = @_;
}
#
# Endup module properly
#
1;

__END__

=pod

=head1  NAME

API::Eulerian::EDW::Hook - Eulerian Data Warehouse Peer Hook module.

=head1 DESCRIPTION

This module provides callback hooks interface used to process analysis reply
data. Library user can create their own derived class matching this module
interface. It permits to process reply data in a specific manner.

=head1 METHODS

=head2 new()

I<Create a new instance of Eulerian Data Warehouse Peer Hook>

=head3 input

=over 4

=item * setup - Hash reference of Hook parameters.

=back

=head3 output

=over 4

=item * API::Eulerian::EDW::Hook instance.

=back

=head2 setup()

I<Setup Eulerian Data Warehouse Peer Hook>

=head3 input

=over 4

=item * setup - Hash reference of Hook parameters.

=back

=head2 on_headers()

I<Interface definition of the callback function used whenever a new Eulerian
Data Warehouse Started.>

=head3 input

=over 4

=item * uuid - Eulerian Data Warehouse Analysis identifier.

=item * start - UNIX Timestamp of the beginning of Eulerian Data Warehouse Analysis.

=item * end - UNIX Timestamp of the end of Eulerian Data Warehouse Analysis.

=item * headers - Perl Array of Columns headers.

=back

=head2 on_add()

I<Interface definition of the callback function used to proceed an Eulerian Data
Warehouse Row outputs Analysis.>

=head3 input

=over 4

=item * uuid - Eulerian Data Warehouse Analysis identifier.

=item * rows - Array of Array of columns values.

=back

=head2 on_replace()

I<Interface definition of the callback function used to proceed an Eulerian Data
Warehouse Distinct and Pivot outputs Analysis.>

=head3 input

=over 4

=item * uuid - Eulerian Data Warehouse Analysis identifier.

=item * rows - Array of Array of columns values.

=back

=head2 on_progress()

I<Interface definition of the callback function used to control the progression
of an Eulerian Data Warehouse Analysis.>

=head3 input

=over 4

=item * uuid - Eulerian Data Warehouse Analysis identifier.

=item * progress - Progression value.

=back

=head2 on_status()

I<Interface definition of the callback function called at the end of an Eulerian
Data Warehouse Analysis.>

=head3 input

=over 4

=item * uuid - Eulerian Data Warehouse Analysis identifier.

=item * token - AES token.

=item * errnum - Error number.

=item * err - Error message.

=item * updated - Updated events count.

=back

=head1 AUTHOR

Xavier Thorillon <x.thorillon@eulerian.com>

=head1 COPYRIGHT

Copyright (c) 2008 Eulerian Technologies Ltd L<http://www.eulerian.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA

=cut
