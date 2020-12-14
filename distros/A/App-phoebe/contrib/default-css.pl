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
use File::Slurper qw(read_text);

our ($server, $log);

# redefining!
sub serve_css_via_http {
  my $stream = shift;
  $log->debug("Serving default.css via HTTP");
  $stream->write("HTTP/1.1 200 OK\r\n");
  $stream->write("Content-Type: text/css\r\n");
  $stream->write("Cache-Control: public, max-age=86400, immutable\r\n"); # 24h
  $stream->write("\r\n");
  my $dir = $server->{wiki_dir};
  $stream->write(read_text("$dir/default.css"));
}
