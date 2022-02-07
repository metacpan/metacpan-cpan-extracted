#/usr/bin/env perl
###############################################################################
#
# @file File.pm
#
# @brief API::Eulerian::EDW::File module used to manage local file system.
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
package API::Eulerian::EDW::File;
#
# Enforce compilor rules
#
use strict; use warnings;
#
# Import API::Eulerian::EDW::Status
#
use API::Eulerian::EDW::Status;
#
# @brief Read file content.
#
# @param path - File path.
#
# @return API::Eulerian::EDW::Status
#
sub read
{
  my $status = API::Eulerian::EDW::Status->new();
  my ( $class, $path ) = @_;
  my $data;
  my $fd;
  # Open file for reading
  open $fd, "<", $path or do {
    $status->error( 1 );
    $status->code( -1 );
    $status->msg( "Opening file : $path for reading failed. $!" );
    return $status;
  };
  # Read file content
  $data = do { local $/; <$fd> };
  # Close file
  close $fd;
  # Save content
  $status->{ data } = $data;
  return $status;
}
#
# @brief Test if given path is writable.
#
# @param $class - API::Eulerian::EDW::File class.
# @param $path - Filesystem path.
#
# @return 0 - Path isnt writable.
# @return 1 - Path is writable.
#
sub writable
{
  my ( $class, $path ) = @_;
  return -w $path;
}
#
# End up perl module properly
#
1;

__END__

=pod

=head1  NAME

API::Eulerian::EDW::File - API::Eulerian::EDW File module.

=head1 DESCRIPTION

This module is used to manage local file system.

=head1 METHODS

=head2 read()

I<Read the content of a given file path.>

=head3 input

=over 4

=item * File path

=back

=head3 output

=over 4

=item * Instance of an API::Eulerian::EDW::Status. On success, a new entry named 'data' is inserted into
the Status.

=back

=head2 writable()

I<Test if a given path is writable.>

=head3 input

=over 4

=item * File path

=back

=head3 output

=over 4

=item * 1 - Path is writable.

=item * 0 - Path isnt writable.

=back

=head1 SEE ALSO

L<API::Eulerian::EDW::Status>

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
