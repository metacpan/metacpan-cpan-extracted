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

App::Phoebe::MokuPona - serve files from moku pona

=head1 DESCRIPTION

This serves files from your moku pona directory. See L<App::mokupona>.

If you need to change the directory (defaults to C<$HOME/.moku-pona>), or if you
need to change the host (defaults to the first one), use the following for your
F<config> file:

    package App::Phoebe::MokuPona;
    our $dir = "/home/alex/.moku-pona";
    our $host = "alexschroeder.ch";
    use App::Phoebe::MokuPona;

=cut

package App::Phoebe::MokuPona;
use App::Phoebe qw(@extensions $server $log success result port);
use Modern::Perl;
use URI::Escape;
use File::Slurper qw(read_text);
use Encode qw(encode_utf8 decode_utf8);
# moku pona

our $dir  ||= "$ENV{HOME}/.moku-pona";
our $host ||= (keys %{$server->{host}})[0];

push(@extensions, \&mokupona);

sub mokupona {
  my $stream = shift;
  my $url = shift;
  my $port = port($stream);
  if ($url =~ m!^gemini://$host(?::$port)?/do/moku-pona$!) {
    result($stream, "31", "gemini://$host/do/moku-pona/updates.txt");
    return 1;
  } elsif ($url =~ m!^gemini://$host(?::$port)?/do/moku-pona/([^/]+)$!) {
    my $file = decode_utf8(uri_unescape($1));
    if (-f "$dir/$file") {
      success($stream);
      $stream->write(encode_utf8 read_text("$dir/$file"));
    } else {
      result($stream, "40", "Cannot read $dir/$file");
    }
    return 1;
  }
  return 0;
}
