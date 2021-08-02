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

App::Phoebe::StaticFiles - serve static files via a Phoebe wiki

=head1 DESCRIPTION

Serving static files... Sometimes it's just easier. All the static files are
served from C</do/static>, without regard to wiki spaces. You need to define
routes that map a path to your filesystem.

    package App::Phoebe::StaticFiles;
    our %routes = (
      "zürich" => "/home/alex/Pictures/2020/Zürich",
      "amaryllis" => "/home/alex/Pictures/2021/Amaryllis", );
    use App::Phoebe::StaticFiles;

The setup does not allow recursive traversal of the file system.

You still need to add a link to C</do/static> somewhere in your wiki.

=cut

package App::Phoebe::StaticFiles;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(%routes mime_type);
use App::Phoebe qw(@extensions $log host_regex port success result);
use File::Slurper qw(read_text read_binary read_dir);
use Encode qw(encode_utf8 decode_utf8);
use URI::Escape;

# add a code reference to the list of extensions
push(@extensions, \&static_routes);

# a hash mapping routes to the static directories to serve
our %routes;

sub static_routes {
  my ($stream, $url) = @_;
  my $host = host_regex();
  my $port = port($stream);
  if ($url =~ m!^gemini://($host)(?::$port)?/do/static/?$!) {
    $log->debug("Serving the list of static routes");
    success($stream);
    for my $route (sort keys %routes) {
      $stream->write("=> /do/static/" . uri_escape_utf8($route) . " " . encode_utf8($route) . "\n");
    }
    return 1;
  } elsif ($url =~ m!^gemini://($host)(?::$port)?/do/static/([^/]+)/?$!) {
    my $route = decode_utf8(uri_unescape($2));
    my $dir = $routes{$route};
    $log->debug("Serving list of files at $route, reading $dir");
    if ($dir) {
      success($stream);
      for my $file (sort map { decode_utf8($_) } grep !/^\./, read_dir($dir)) {
	$stream->write("=> /do/static/" . uri_escape_utf8($route) . "/" . uri_escape_utf8($file)
		       . " " . encode_utf8($file) . "\n");
      }
    } else {
      result($stream, "40", "Unknown route: " . encode_utf8($route));
    }
    return 1;
  } elsif ($url =~ m!^gemini://($host)(?::$port)?/do/static/([^/]+)/([^.].*)$!i) {
    my $route = decode_utf8(uri_unescape($2));
    my $file = decode_utf8(uri_unescape($3));
    $log->debug("Serving $route/$file");
    my $dir = $routes{$route};
    # no slashes in the file name!
    if ($file !~ /\// and -f "$dir/$file") {
      success($stream, mime_type($file));
      $stream->write(read_binary("$dir/$file"));
    } else {
      result($stream, "40", "Unknown file: " . encode_utf8($file));
    }
    return 1;
  }
  return;
}

# cheap MIME type guessing; alternatively, use File::MimeInfo
sub mime_type {
  $_ = shift;
  return 'text/gemini' if /\.gmi$/i;
  return 'text/plain' if /\.te?xt$/i;
  return 'text/markdown' if /\.md$/i;
  return 'text/html' if /\.html?$/i;
  return 'image/png' if /\.png$/i;
  return 'image/jpeg' if /\.jpe?g$/i;
  return 'image/gif' if /\.gif$/i;
  return 'text/plain'; # or application/octet-stream?
}

1;
