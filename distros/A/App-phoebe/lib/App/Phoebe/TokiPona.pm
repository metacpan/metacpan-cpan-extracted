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

App::Phoebe::TokiPona - serve a linja pona via the web

=head1 DESCRIPTION

This extension adds rendering of Toki Pona glyphs to the web output of your
site. For this to work, you need to download the WOFF file from the Linja Pona
4.2 repository and put it into your wiki directory.

L<https://github.com/janSame/linja-pona/>

No further configuration is necessary. Simply add it to your F<config> file:

    use App::Phoebe::TokiPona;

=cut

package App::Phoebe::TokiPona;
use App::Phoebe::Web;
use App::Phoebe qw(@extensions $server $log);
use File::Slurper qw(read_binary);
use Modern::Perl;

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
*old_serve_css_via_http = \&App::Phoebe::Web::serve_css_via_http;
*App::Phoebe::Web::serve_css_via_http = \&serve_css_via_http;

sub serve_css_via_http {
  my $stream = shift;
  old_serve_css_via_http($stream);
  $log->info("Adding more CSS via HTTP (for toki pona)");
  $stream->write(<<'EOT');
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
