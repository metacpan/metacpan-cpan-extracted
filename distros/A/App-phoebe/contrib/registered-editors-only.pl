# -*- mode: perl -*-
# Copyright (C) 2017–2020  Alex Schroeder <alex@gnu.org>

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

package App::Phoebe;
use Modern::Perl;

=head1 Registered Editors Only

You need to set C<@fingerprints> in your config file. Here's an example:

    our (@fingerprints);
    @fingerprints = qw(
      sha256$fce75346ccbcf0da647e887271c3d3666ef8c7b181f2a3b22e976ddc8fa38401
      sha256$54c0b95dd56aebac1432a3665107d3aec0d4e28fef905020ed6762db49e84ee1);

The way to do it is to request the I<certificate> from your friends (not they
key!) and run the following:

    openssl x509 -in client-cert.pem -noout -sha256 -fingerprint \
    | sed -e 's/://g' -e 's/SHA256 Fingerprint=/sha256$/' \
    | tr [:upper:] [:lower:]

This should give you your friend's fingerprint in the correct format to add to
the list above.

Make sure your main menu has a link to the login page:

    => /login Login

This code works by intercepting all C<titan:> links. Specifically:

=over

=item If you allow simple comments using F<comments.pl>, then those are not
      affected, since these comments use Gemini instead of Titan. Thus, people
      can still leave comments.

=item If you allow editing via the web using F<web-edit.pl>, then those are not
      affected, since these edits use HTTP instead of Titan. Thus, people can
      still edit pages.

=back

=cut

our (@request_handlers, @extensions, @fingerprints, $log);

unshift(@request_handlers, '^titan://' => \&protected_titan);

sub protected_titan {
  my $stream = shift;
  my $data = shift;
  my $hosts = host_regex();
  my $spaces = space_regex();
  my $port = port($stream);
  my $fingerprint = $stream->handle->get_fingerprint();
  if ($fingerprint and grep { $_ eq $fingerprint} @fingerprints) {
    $log->info("Successfully identified client certificate");
    return handle_titan($stream, $data);
  } elsif ($fingerprint) {
    $log->info("Unknown client certificate $fingerprint");
    $stream->write("61 Your client certificate is not authorized for editing\r\n");
  } else {
    $log->info("Requested client certificate");
    $stream->write("60 You need a client certificate to edit this wiki\r\n");
  }
  $stream->close_gracefully();
}

push(@extensions, \&registered_editor_login);

sub registered_editor_login {
  my $stream = shift;
  my $url = shift;
  my $hosts = host_regex();
  my $spaces = space_regex();
  my $port = port($stream);
  my $fingerprint = $stream->handle->get_fingerprint();
  my $host;
  if (($host) = $url =~ m!^gemini://($hosts)(?::$port)?/login!) {
    if ($fingerprint and grep { $_ eq $fingerprint} @fingerprints) {
      $log->info("Successfully identified client certificate");
      $stream->write("30 gemini://$host:$port/\r\n");
    } elsif ($fingerprint) {
      $log->info("Unknown client certificate $fingerprint");
      $stream->write("61 Your client certificate is not known\r\n");
    } else {
      $log->info("Requested client certificate");
      $stream->write("60 You need a client certificate to edit this wiki\r\n");
    }
    return 1;
  }
  return;
}

1;
