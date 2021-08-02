# -*- mode: perl -*-
# Copyright (C) 2021  Alex Schroeder <alex@gnu.org>

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

=encoding utf8

=head1 NAME

App::Phoebe::Iapetus - uploads using the Iapetus protocol

=head1 DESCRIPTION

This allows known editors to upload files and pages using the Iapetus protocol.
See L<Iapetus documentation|https://codeberg.org/oppenlab/iapetus>.

In order to be a known editor, you need to set C<@known_fingerprints> in your
F<config> file. Here’s an example:

    package App::Phoebe;
    our @known_fingerprints;
    @known_fingerprints = qw(
      sha256$fce75346ccbcf0da647e887271c3d3666ef8c7b181f2a3b22e976ddc8fa38401
      sha256$54c0b95dd56aebac1432a3665107d3aec0d4e28fef905020ed6762db49e84ee1);
    use App::Phoebe::Iapetus;

The way to do it is to run the following, assuming the certificate is named
F<client-cert.pem>:

    openssl x509 -in client-cert.pem -noout -sha256 -fingerprint \
    | sed -e 's/://g' -e 's/SHA256 Fingerprint=/sha256$/' \
    | tr [:upper:] [:lower:]

This should give you the fingerprint in the correct format to add to the list
above.

Make sure your main menu has a link to the login page. The login page allows
people to pick the right certificate without interrupting their uploads.

    => /login Login

=cut

package App::Phoebe::Iapetus;
use App::Phoebe qw($server $log @request_handlers @extensions host_regex space_regex space port result
		   valid_id valid_mime_type valid_size @known_fingerprints process_titan);
use Modern::Perl;
use File::MimeInfo qw(globs);
use Encode qw(decode_utf8);
use URI::Escape;

push(@{$server->{wiki_mime_type}},'text/gemini');
unshift(@request_handlers, '^iapetus://' => \&handle_iapetus);

sub handle_iapetus {
  my $stream = shift;
  my $data = shift;
  # extra processing of the request if we didn't do that, yet
  return setup_iapetus($stream, $data) unless $data->{upload};
  my $size = $data->{upload}->{params}->{size};
  my $actual = length($data->{buffer});
  if ($actual == $size) {
    $log->debug("Handle Iapetus request as Titan request");
    process_titan($stream, $data->{request}, $data->{upload}, $data->{buffer}, $size);
    # do not close in case we're waiting for the lock
    return;
  } elsif ($actual > $size) {
    $log->debug("Received more than the promised $size bytes");
    result($stream, "59", "Received more than the promised $size bytes");
    $stream->close_gracefully();
    return;
  }
  $log->debug("Waiting for " . ($size - $actual) . " more bytes");
}

sub setup_iapetus {
  my $stream = shift;
  my $data = shift;
  my $request = $data->{request};
  $log->info("Looking at $request");
  my $hosts = host_regex();
  my $spaces_regex = space_regex();
  my $port = port($stream);
  if ($request =~ m!^iapetus://($hosts)(?::$port)?!) {
    my $host = $1;
    my($scheme, $authority, $path, $query, $fragment, $size) =
	$request =~ m|(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(\S*))?\s+(\d+)|;
    if ($path =~ m!^(?:/($spaces_regex))?(?:/raw)?/([^/;=&]+)!) {
      my ($space, $id) = ($1, $2);
      return unless valid_id($stream, $host, $space, $id);
      my $type = globs($id) || mime_type($id);
      my $params = { size => $size, mime => $type };
      return unless valid_mime_type($stream, $host, $space, $id, $params);
      return unless valid_size($stream, $host, $space, $id, $params);
      return unless valid_client_cert($stream, $host, $space, $id, $params);
      $data->{upload} = {
	host => $host,
	space => space($stream, $host, $space),
	id => decode_utf8(uri_unescape($id)),
	params => $params,
      };
      result($stream, "10", "Continue"); # weird!
      return 1;
    } else {
      $log->debug("The path $path is malformed");
      result($stream, "59", "The path $path is malformed");
      $stream->close_gracefully();
    }
  }
  return 0;
}

# fallback if File::MimeInfo found no data files
sub mime_type {
  $_ = shift;
  return 'text/gemini' if /\.gmi$/i;
  return 'text/plain' if /\.te?xt$/i;
  return 'text/markdown' if /\.md$/i;
  return 'text/html' if /\.html?$/i;
  return 'image/png' if /\.png$/i;
  return 'image/jpeg' if /\.jpe?g$/i;
  return 'image/gif' if /\.gif$/i;
  return 'text/plain'; # this is what phoebe expects
}

# duplicates functionality from registered_editor_login.pl

sub valid_client_cert {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $fingerprint = $stream->handle->get_fingerprint();
  if ($fingerprint and grep { $_ eq $fingerprint} @known_fingerprints) {
    $log->info("Successfully identified client certificate");
    return 1;
  } elsif ($fingerprint) {
    $log->info("Unknown client certificate $fingerprint");
    result($stream, "61", "Your client certificate is not authorized for editing");
  } else {
    $log->info("Requested client certificate");
    result($stream, "60", "You need a client certificate to edit this wiki");
  }
  $stream->close_gracefully();
  return;
}

# also duplicates functionality from registered_editor_login.pl

push(@extensions, \&iapetus_login);

sub iapetus_login {
  my $stream = shift;
  my $url = shift;
  my $hosts = host_regex();
  my $spaces = space_regex();
  my $port = port($stream);
  my $fingerprint = $stream->handle->get_fingerprint();
  my $host;
  if (($host) = $url =~ m!^gemini://($hosts)(?::$port)?/login!) {
    if ($fingerprint and grep { $_ eq $fingerprint} @known_fingerprints) {
      $log->info("Successfully identified client certificate");
      result($stream, "30", "gemini://$host:$port/");
    } elsif ($fingerprint) {
      $log->info("Unknown client certificate $fingerprint");
      result($stream, "61", "Your client certificate is not known");
    } else {
      $log->info("Requested client certificate");
      result($stream, "60", "You need a client certificate to edit this wiki");
    }
    return 1;
  }
  return;
}
