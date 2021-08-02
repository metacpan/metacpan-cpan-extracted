# -*- mode: perl -*-
# Copyright (C) 2017–2021  Alex Schroeder <alex@gnu.org>

# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <https://www.gnu.org/licenses/>.

=head1 NAME

App::Phoebe::DebugIpNumbers - log visitor IP numbers for Phoebe

=head1 DESCRIPTION

By default the IP numbers of your visitors are not logged. This small extensions
allows you to log them anyway if you're trying to figure out whether a bot is
going crazy.

There is no configuration. Simply add it to your F<config> file:

    use App::Phoebe::DebugIpNumbers;

Phoebe tries not to collect visitor data. Logging visitor IP numbers goes
against this. If your aim is detect and block crazy bots by having C<fail2ban>
watch the log files, consider using L<App::Phoebe::SpeedBump> instead.

=cut

package App::Phoebe::DebugIpNumbers;
use App::Phoebe qw($log);
use Modern::Perl;

# We have to override the copy that was imported into the main namespace in the
# start_servers subroutine.
no warnings 'redefine';
*old_handle_request = \&main::handle_request;
*main::handle_request = \&handle_request;

sub handle_request {
  my ($stream) = @_;
  my $address = $stream->handle->peerhost;
  $log->debug("Visitor: $address");
  return old_handle_request(@_);
}

1;
