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

App::Phoebe::Favicon - serve a favicon via the web for Phoebe

=head1 DESCRIPTION

This adds an ominous looking Jupiter planet SVG icon as the favicon for the web
view of your site.

There is no configuration. Simply add it to your F<config> file:

    App::Phoebe::Favicon

It would be nice if this code were to look for a F<favicon.jpg> or
F<favicon.svg> in the data directory and served that, only falling back to the
Jupiter planet SVG if no such file can be found. We could cache the content of
the file in the C<$server> hash reference… Well, if somebody writes it, it shall
be merged. 😃

=cut

package App::Phoebe::Favicon;
use App::Phoebe qw(@extensions $log);
use App::Phoebe::Web;
use Modern::Perl;

push(@extensions, \&favicon);

sub favicon {
  my $stream = shift;
  my $request = shift;
  if ($request =~ m!^GET /favicon.ico HTTP/1\.[01]$!) {
    serve_favicon_via_http($stream);
    return 1;
  }
  return 0;
}

sub serve_favicon_via_http {
  my $stream = shift;
  $log->info("Serving favicon via HTTP");
  $stream->write("HTTP/1.1 200 OK\r\n");
  $stream->write("Content-Type: image/svg+xml\r\n");
  $stream->write("Cache-Control: public, max-age=86400, immutable\r\n"); # 24h
  $stream->write("\r\n");
  $stream->write(<<'EOT');
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
<circle cx="50" cy="50" r="45" fill="white" stroke="black" stroke-width="5"/>
<line x1="12" y1="25" x2="88" y2="25" stroke="black" stroke-width="4"/>
<line x1="5" y1="45" x2="95" y2="45" stroke="black" stroke-width="7"/>
<line x1="5" y1="60" x2="95" y2="60" stroke="black" stroke-width="4"/>
<path d="M20,73 C30,65 40,63 60,70 C70,72 80,73 90,72
         L90,74 C80,75 70,74 60,76 C40,83 30,81 20,73" fill="black"/>
<ellipse cx="40" cy="73" rx="11.5" ry="4.5" fill="red"/>
<line x1="22" y1="85" x2="78" y2="85" stroke="black" stroke-width="3"/>
</svg>
EOT
}
