#/usr/bin/env perl
###############################################################################
#
# @file Chrono.pm
#
# @brief API::Eulerian::EDW::Chrono module used to compute elapsed time between two
#        calls.
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
package API::Eulerian::EDW::Chrono;
#
# Enforce compilor rules
#
use strict; use warnings;
#
# Import gettimeofday, tv_interval
#
use Time::HiRes qw( gettimeofday tv_interval );
#
# @brief Allocate and initialize a new API::Eulerian::EDW Chrono instance.
#
# @return API::Eulerian::EDW::Chrono instance.
#
sub new
{
  return bless( {
      _CHRONO => [ gettimeofday ],
    }, shift
  );
}
#
# @brief Get Elapsed time between Chrono creation and call to elapsed.
#
# @param $self - API::Eulerian::EDW::Chrono instance.
#
# @return Elapsed time ( secondes.microsecondes )
#
sub elapsed
{
  return tv_interval( shift->{ _CHRONO }, [ gettimeofday ] );
}
#
# Endup module properly
#
1;

__END__

=pod

=head1  NAME

API::Eulerian::EDW::Chrono - API::Eulerian::EDW Chrono module.

=head1 DESCRIPTION

This module is used to count elapsed time.

=head1 METHODS

=head2 new()

I<Allocate and initialize a new API::Eulerian::EDW::Chrono instance>

=head3 output

=over 4

=item * API::Eulerian::EDW::Chrono instance.

=back

=head2 elapsed()

I<Get elapsed time since Chrono creation>

=head3 input

=over 4

=item * API::Eulerian::EDW::Chrono instance.

=back

=head3 output

=over 4

=item * Elapsed time secondes.microsecondes.

=back

=head1 SEE ALSO

L<Time::HiRes>

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
