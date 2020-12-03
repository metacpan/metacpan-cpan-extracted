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

our (@extensions);

# moku pona

my $moku_pona_dir = "/home/alex/.moku-pona";

push(@extensions, \&mokupona);

sub mokupona {
  my $stream = shift;
  my $url = shift;
  my $host = "alexschroeder.ch";
  my $port = port($stream);
  if ($url =~ m!^gemini://$host(?::$port)?/do/moku-pona$!) {
    $stream->write("31 gemini://$host/do/moku-pona/updates.txt\r\n");
  } elsif ($url =~ m!^gemini://$host(?::$port)?/do/moku-pona/([^/]+)$!) {
    my $file = decode_utf8(uri_unescape($1));
    if (-f "$moku_pona_dir/$file") {
      $stream->write("20 text/gemini\r\n");
      $stream->write(encode_utf8 read_text("$moku_pona_dir/$file"));
    } else {
      $stream->write("40 Cannot read $moku_pona_dir/$file\r\n");
    }
  } else {
    return 0;
  }
  return 1;
}
