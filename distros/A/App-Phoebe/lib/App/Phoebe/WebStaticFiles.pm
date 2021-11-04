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

App::Phoebe::WebStaticFiles - serve static files via the web

=head1 DESCRIPTION

Serving static files, via the web. This is an add-on to L<App::Phoebe::Web> and
L<App::Phoebe::StaticFiles>.

Here is an example setup where we assume that the route contains an UTF-8
encoded characters, and the directory name used also contains UTF-8 encoded
characters.

    package App::Phoebe::StaticFiles;
    use utf8;
    our %routes = (
      "zürich" => "/home/alex/Pictures/2020/Zürich",
      "amaryllis" => "/home/alex/Pictures/2021/Amaryllis", );
    use App::Phoebe::WebStaticFiles;

The setup does not allow recursive traversal of the file system.

You still need to add a link to C</do/static> somewhere in your wiki.

=cut

package App::Phoebe::WebStaticFiles;
use App::Phoebe qw(@extensions $log host_regex port);
use App::Phoebe::Web qw(http_error);
use App::Phoebe::StaticFiles qw(%routes mime_type);
use File::Slurper qw(read_text read_binary read_dir);
use Encode qw(encode_utf8 decode_utf8);
use Modern::Perl;
use URI::Escape;

# add a code reference to the list of extensions
push(@extensions, \&static_web_routes);

sub static_web_routes {
  my ($stream, $request, $headers) = @_;
  my $hosts = host_regex();
  my $port = port($stream);
  my ($host, $route, $file);
  if ($request =~ m!^GET /do/static/? HTTP/1\.[01]$!
      and ($host) = $headers->{host} =~ m!^($hosts)(?::$port)$!) {
    $log->debug("Serving the list of static routes via the web");
    $stream->write("HTTP/1.1 200 OK\r\n");
    $stream->write("Content-Type: text/html\r\n");
    $stream->write("\r\n");
    $stream->write("<!DOCTYPE html>\n");
    $stream->write("<html>\n");
    $stream->write("<head>\n");
    $stream->write("<meta charset=\"utf-8\">\n");
    $stream->write("<title>All Directories</title>\n");
    $stream->write("<link type=\"text/css\" rel=\"stylesheet\" href=\"/default.css\"/>\n");
    $stream->write("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
    $stream->write("</head>\n");
    $stream->write("<body>\n");
    $stream->write("<h1>All Directories</h1>\n");
    $stream->write("<ul>\n");
    for my $route (sort keys %routes) {
      $stream->write("<li><a href=\"/do/static/" . uri_escape_utf8($route) . "\">"
		     . encode_utf8($route) . "</a>\n");
    }
    $stream->write("</ul>\n");
    $stream->write("</body>\n");
    $stream->write("</html>\n");
    return 1;
  } elsif (($route) = $request =~ m!^GET /do/static/([^/]+)/? HTTP/1\.[01]$!
      and ($host) = $headers->{host} =~ m!^($hosts)(?::$port)$!) {
    my $route = decode_utf8(uri_unescape($route));
    my $dir = $routes{$route};
    if (not $dir) {
      http_error($stream, "Unknown route: " . encode_utf8($route));
      return 1;
    }
    $log->debug("Serving list of files at $route via the web, reading $dir");
    $stream->write("HTTP/1.1 200 OK\r\n");
    $stream->write("Content-Type: text/html\r\n");
    $stream->write("\r\n");
    $stream->write("<!DOCTYPE html>\n");
    $stream->write("<html>\n");
    $stream->write("<head>\n");
    $stream->write("<meta charset=\"utf-8\">\n");
    $stream->write("<title>Files</title>\n");
    $stream->write("<link type=\"text/css\" rel=\"stylesheet\" href=\"/default.css\"/>\n");
    $stream->write("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
    $stream->write("</head>\n");
    $stream->write("<body>\n");
    $stream->write("<h1>Files</h1>\n");
    $stream->write("<ul>\n");
    for my $file (sort map { decode_utf8($_) } grep !/^\./, read_dir($dir)) {
      $stream->write(encode_utf8 "<li><a href=\"/do/static/" . uri_escape_utf8($route) . "/"
		     . uri_escape_utf8($file) . "\">"
		     . encode_utf8($file) . "</a>\n");
    }
    $stream->write("</ul>\n");
    $stream->write("</body>\n");
    $stream->write("</html>\n");
    return 1;
  } elsif (($route, $file) = $request =~ m!^GET /do/static/([^/]+)/([^.].*) HTTP/1\.[01]$!
      and ($host) = $headers->{host} =~ m!^($hosts)(?::$port)$!) {
    my $route = decode_utf8(uri_unescape($route));
    my $file = decode_utf8(uri_unescape($file));
    $log->debug("Serving $route/$file via the web");
    my $dir = $routes{$route};
    # no slashes in the file name!
    if ($file =~ /\// or not $dir or not -f "$dir/$file") {
      http_error($stream, "Unknown file: " . encode_utf8($file));
      return 1;
    }
    my $mime = mime_type($file);
    $stream->write("HTTP/1.1 200 OK\r\n");
    $stream->write("Content-Type: $mime\r\n");
    $stream->write("\r\n");
    $stream->write(read_binary("$dir/$file"));
    return 1;
  }
  return;
}
