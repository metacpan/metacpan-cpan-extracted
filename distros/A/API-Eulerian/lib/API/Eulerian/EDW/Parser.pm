#/usr/bin/env perl
###############################################################################
#
# @file Parser.pm
#
# @brief Eulerian Data Warehouse REST Parser Module definition.
#
# This module is the base class of every input file parser.
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
package API::Eulerian::EDW::Parser;
#
# Enforce compilor rules
#
use strict; use warnings;
#
# @brief Allocate and initialize a new API::Eulerian::EDW::Parser instance.
#
# @param $class - API::Eulerian::EDW::Parser class.
# @param $path - Input file path.
# @param $uuid - Eulerian Data Warehouse Analysis UUID.
#
# @return API::Eulerian::EDW::Parser instance.
#
sub new
{
  my ( $class, $path, $uuid ) = @_;
  return bless( {
      _PATH => $path,
      _UUID => $uuid,
    }, $class );
}
#
# @brief Get/Set Eulerian Data Warehouse Analysis UUID.
#
# @param $self - API::Eulerian::EDW::Parser instance.
# @param $uuid - Eulerian Data Warehouse Analysis UUID.
#
# @return Eulerian Data Warehouse Analysis UUID.
#
sub uuid
{
  my ( $self, $uuid ) = @_;
  $self->{ _UUID } = $uuid if $uuid;
  return $self->{ _UUID };
}
#
# @brief Get/Set Input file path.
#
# @parm $self - API::Eulerian::EDW::Parser instance.
#
# @return Input file path.
#
sub path
{
  my ( $self, $path ) = @_;
  $self->{ _PATH } = $path if $path;
  return $self->{ _PATH };
}
#
# @brief Parse input file path and call user specific hook.
#
# @param $self - API::Eulerian::EDW::Parser instance.
# @param $hook - API::Eulerian::EDW::Hook instance.
#
sub do {}
#
# Endup module properly
#
1;

__END__

=pod

=head1  NAME

API::Eulerian::EDW::Hook - Eulerian Data Warehouse Hook module.

=head1 DESCRIPTION

This module is the base interface of an input file parser.

=head1 METHODS

=head2 new()

I<Allocate and initialize a new API::Eulerian::EDW::Hook instance.>

=head3 input

=over 4

=item * path - Input file path.

=item * uuid - Eulerian Data Warehouse Analysis UUID.

=back

=head3 output

=over 4

=item * Instance of an API::Eulerian::EDW::Parser.

=back

=head2 uuid()

I<Get/Set Eulerian Data Warehouse Analysis UUID.>

=head3 input

=over 4

=item * uuid - Eulerian Data Warehouse Analysis UUID.

=back

=head3 output

=over 4

=item * Eulerian Data Warehouse Analysis UUID.

=back

=head2 path()

I<Get/Set input file path.>

=head3 input

=over 4

=item * path - Input file path.

=back

=head3 output

=over 4

=item * Input file path.

=back

=head2 do()

I<Parse input file path, call user specific hook.>

=head3 input

=over 4

=item * hook - API::Eulerian::EDW::Hook instance.

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
