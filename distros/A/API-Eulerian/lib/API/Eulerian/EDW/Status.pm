#/usr/bin/env perl
###############################################################################
#
# @file Status.pm
#
# @brief API::Eulerian::EDW Status used to return function error to the callers
#
# @author Thorillon Xavier:x.thorillon@eulerian.com
#
# @date 25/11/2021
#
# @version 1.0
#
###############################################################################
#
# Setup perl package name
#
package API::Eulerian::EDW::Status;
#
# Enforce compilor rules
#
use strict; use warnings;
#
# @brief Allocate and initialize a new API::Eulerian::EDW::Status instance.
#
# @param $class - API::Eulerian::EDW::Status class.
#
# @return API::Eulerian::EDW::Status instance.
#
sub new
{
  my ( $class ) = @_;
  return bless( {
      _ERROR => 0,
      _MSG => '',
      _CODE => 0,
    }, $class
  );
}
#
# @brief Get/Set error message.
#
# @param $self - API::Eulerian::EDW::Status instance.
# @param $msg - Error message.
#
# @return Error message.
#
sub msg
{
  my ( $self, $msg ) = @_;
  $self->{ _MSG } = $msg if defined( $msg );
  return $self->{ _MSG };
}
#
# @brief Get/Set error code.
#
# @param $self - API::Eulerian::EDW::Status instance.
# @param $code - Error code.
#
# @return Error code.
#
sub code
{
  my ( $self, $code ) = @_;
  $self->{ _CODE } = $code if defined( $code );
  return $self->{ _CODE };
}
#
# @brief Get/Set error.
#
# @param $self - API::Eulerian::EDW::Status instance.
# @param $error - Error.
#
# @return Error flag.
#
sub error
{
  my ( $self, $error ) = @_;
  $self->{ _ERROR } = $error if defined( $error );
  return $self->{ _ERROR };
}
sub path
{
  my $self = shift;
  return $self->{ path };
}
#
# @brief Dump status.
#
# @param $self - API::Eulerian::EDW::Status.
#
sub dump
{
  my ( $self ) = @_;
  my $error = $self->error() ? 'Yes' : 'No';
  my $code = $self->code();
  my $msg = $self->msg();
  my $string = <<string_end;
    Error   : $error
    Code    : $code
    Message : $msg
string_end
  print( $string );
}
#
# End up perl module properly
#
1;

__END__

=pod

=head1  NAME

API::Eulerian::EDW::Status - API::Eulerian::EDW Status module.

=head1 DESCRIPTION

This module provide a Perl Status object used as return to function calls.

=head1 METHODS

=head2 new()

I<Create a new API::Eulerian::EDW::Status instance.>

=head3 output

=over 4

=item * Instance of an API::Eulerian::EDW::Status.

=back

=head2 error()

I<Get/Set error flag.>

=head3 input

=over 4

=item * [optional] Error flag.

=back

=head3 output

=over 4

=item * Error flag.

=back

=head2 msg()

I<Get/Set status message.>

=head3 input

=over 4

=item * [optional] Status message.

=back

=head3 output

=over 4

=item * Status message.

=back

=head2 code()

I<Get/Set status code.>

=head3 input

=over 4

=item * [optional] Status code.

=back

=head3 output

=over 4

=item * Status code.

=back

=head2 dump()

I<Dump status>

=head1 AUTHOR

Xavier Thorillon <x.thorillon@eulerian.com>

=head1 COPYRIGHT

Copyright (c) 2008 API::Eulerian::EDW Technologies Ltd L<http://www.eulerian.com>

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
