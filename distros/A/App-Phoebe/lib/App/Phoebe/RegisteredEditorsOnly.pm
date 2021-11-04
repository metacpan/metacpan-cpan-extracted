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

=encoding utf8

=head1 NAME

App::Phoebe::RegisteredEditorsOnly - only known users may edit Phoebe wiki pages

=head1 DESCRIPTION

This extension limits editing to registered editors only. In order to register
an editor, you need to know the client certificate's fingerprint, and add it to
the Phoebe wiki F<config> file. Do this by setting C<@known_fingerprints>.
Here’s an example:

    package App::Phoebe;
    our @known_fingerprints = qw(
      sha256$fce75346ccbcf0da647e887271c3d3666ef8c7b181f2a3b22e976ddc8fa38401
      sha256$54c0b95dd56aebac1432a3665107d3aec0d4e28fef905020ed6762db49e84ee1);
    use App::Phoebe::RegisteredEditorsOnly;
    our $server->{wiki_token} = []; # no tokens
    1;

If you have your editor’s client certificate (not their key!), run the
following to get the fingerprint:

    openssl x509 -in client-cert.pem -noout -sha256 -fingerprint \
    | sed -e 's/://g' -e 's/SHA256 Fingerprint=/sha256$/' \
    | tr [:upper:] [:lower:]

This should give you the fingerprint in the correct format to add to the list
above. Add it, and restart Phoebe.

If a visitor uses a fingerprint that Phoebe doesn’t know, the fingerprint is
printed in the log (if your log level is set to “info” or more), so you can get
it from there in case the user can’t send you their client certificate, or tell
you what the fingerprint is.

You should also have a login link somewhere such that people can login
immediately. If they don’t, and they try to save, their client is going to ask
them for a certificate and their edits may or may not be lost. It depends. 😅

    => /login Login

This code works by intercepting all C<titan:> links, and all web edit requests.
If you allow editing via the web using L<App::Phoebe::WebEdit>, then those also
require a valid client certificate – and setting these up in a web browser are
not easy. Be prepared to explain how to do this to your users!

This code does I<not> prevent simple comments using L<App::Phoebe::Comments> or
L<App::Phoebe::WebComments>. People can still leave comments, if you use these
modules. This can be a problem: if only registered users can edit the site, you
probably don’t want a token; if anonymous users can comment, you probably want a
token. There is currently no solution for this. Choose one or the other. If you
choose both, registered users might have to provide a token, which might annoy
them.

Here’s an example config that allows reading and editing via the web, but only
for users with known fingerprints, with no comments and no tokens:

    # tested by t/example-registered-editors-only.t
    package App::Phoebe;
    use App::Phoebe::Web;
    use App::Phoebe::WebEdit;
    use App::Phoebe::RegisteredEditorsOnly;
    our @known_fingerprints = qw(
      sha256$0ba6ba61da1385890f611439590f2f0758760708d1375859b2184dcd8f855a00);
    our $server->{wiki_token} = []; # no tokens
    1;

At the time of this writing, here’s a way to do provide a client certificate for
Firefox users. First, we need a file in the C<PKCS12> format. On the command
line, create this file from the F<cert.pem> and F<key.pem> files you have.
Provide no password when you run the command.

    openssl pkcs12 -export -inkey key.pem -in cert.pem -out cert.p12

In Firefox, go to “Preferences” → “Privacy & Security” → “Certificates”; under
“When a server requests your personal certificate” check the option “Select one
automatically”; click on the “View Certificates” button, switch to the “Your
Certificates” tab, click on “Import…” and pick the F<cert.p12> file you just
created.

Once you have done this and you visit the Phoebe site, it’ll use the client
certificate you provided or it’ll ask you what client certificate to use.

=cut

package App::Phoebe::RegisteredEditorsOnly;
use App::Phoebe qw(@request_handlers @extensions @known_fingerprints $log
		   port host_regex space_regex handle_titan result);
use Modern::Perl;

unshift(@request_handlers, '^titan://' => \&protected_titan);

sub protected_titan {
  my $stream = shift;
  my $data = shift;
  my $hosts = host_regex();
  my $spaces = space_regex();
  my $port = port($stream);
  my $fingerprint = $stream->handle->get_fingerprint();
  if ($fingerprint and grep { $_ eq $fingerprint} @known_fingerprints) {
    $log->info("Successfully identified client certificate");
    return handle_titan($stream, $data);
  } elsif ($fingerprint) {
    $log->info("Unknown client certificate $fingerprint");
    result($stream, "61", "Your client certificate is not authorized for editing");
  } else {
    $log->info("Requested client certificate");
    result($stream, "60", "You need a client certificate to edit this wiki");
  }
  $stream->close_gracefully();
}

# for App::Phoebe::WebEdit
unshift(@extensions, \&protect_edit_requests);

sub protect_edit_requests {
  my ($stream, $request, $headers, $buffer) = @_;
  my $host_regex = host_regex();
  my $spaces = space_regex();
  my $port = port($stream);
  if ($request =~ m!^GET (?:/($spaces))?/do/edit/([^/#?]+) HTTP/1\.[01]$!
      or $request =~ m!^POST (?:/($spaces))?/do/edit/([^/#?]+) HTTP/1\.[01]$!) {
    # we don’t check $space and $host like we do in App::Phoebe::WebEdit!
    my $fingerprint = $stream->handle->get_fingerprint();
    if ($fingerprint and grep { $_ eq $fingerprint} @known_fingerprints) {
      $log->info("Successfully identified client certificate via the web");
      return 0; # let it be handled by process_edit_request in App::Phoebe::WebEdit!
    } elsif ($fingerprint) {
      $log->info("Unknown client certificate $fingerprint via the web");
      $stream->write("HTTP/1.1 403 Not authorized\r\n");
      $stream->write("Content-Type: text/plain\r\n");
      $stream->write("\r\n");
      $stream->write("Your client certificate is not authorized for editing\n");
      return 1; # we handled it, no further action required
    } else {
      $log->info("Requested client certificate via the web");
      $stream->write("HTTP/1.1 403 Not authorized\r\n");
      $stream->write("Content-Type: text/plain\r\n");
      $stream->write("\r\n");
      $stream->write("You need a client certificate to edit this wiki");
      return 1; # we handled it, no further action required
    }
  }
  return 0;
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

1;
