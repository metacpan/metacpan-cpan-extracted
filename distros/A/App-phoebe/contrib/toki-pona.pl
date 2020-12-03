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

our (@extensions, $server, $log);

## Toki Pona Font

push(@extensions, \&toki_pona_font);

sub toki_pona_font {
  my $stream = shift;
  my $request = shift;
  if ($request =~ m!^GET /linja-pona-4.2.woff HTTP/1\.[01]$!) {
    serve_font_via_http($stream);
    return 1;
  }
  return 0;
}

sub serve_font_via_http {
  my $stream = shift;
  $log->info("Serving font via HTTP");
  $stream->write("HTTP/1.1 200 OK\r\n");
  $stream->write("Content-Type: font/woff\r\n");
  $stream->write("Cache-Control: public, max-age=86400, immutable\r\n"); # 24h
  $stream->write("\r\n");
  my $dir = $server->{wiki_dir};
  $stream->write(read_binary("$dir/linja-pona-4.2.woff"));
}

# CSS

no warnings qw(redefine);
sub serve_css_via_http {
  my $stream = shift;
  $log->info("Serving CSS via HTTP (toki-pona)");
  $stream->write("HTTP/1.1 200 OK\r\n");
  $stream->write("Content-Type: text/css\r\n");
  $stream->write("Cache-Control: public, max-age=86400, immutable\r\n"); # 24h
  $stream->write("\r\n");
  $stream->write(<<'EOT');
html { max-width: 70ch; padding: 2ch; margin: auto; }
body { color: #111111; background-color: #fffff8; }
a:link { color: #0000ee }
a:visited { color: #551a8b }
a:hover { color: #7a67ee }
@media (prefers-color-scheme: dark) {
   body { color: #eeeee8; background-color: #333333; }
   a:link { color: #1e90ff }
   a:hover { color: #63b8ff }
   a:visited { color: #7a67ee }
}
pre.poetry { font-family: serif; font-style: italic; }
@font-face {
  font-family: linja-pona;
  src: url('/linja-pona-4.2.woff') format('woff');
  font-weight: normal;
  font-style: normal;
}
pre.toki {
  font-family: linja-pona;
  font-feature-settings: "liga" 1, "clig" 1, "calt" 1, "kern" 1, "mark" 1;
  text-rendering: optimizeLegibility;
  font-size: 150%;
}
EOT
}
