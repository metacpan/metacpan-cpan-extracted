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
use Encode qw(encode_utf8);

# Blogging where the first level headers in the page takes precedence over the
# filename.

our (@extensions, $server, $log);
push(@extensions, \&serve_minimal_main_menu);

# We want to serve a different main page if no page was specified.
sub serve_minimal_main_menu {
  my $stream = shift;
  my $url = shift;
  my $hosts = host_regex();
  my $port = port($stream);
  my $spaces = space_regex();
  my ($host, $space);
  if (($host, $space) = $url =~ m!^(?:gemini:)?//($hosts)(?::$port)?(?:/($spaces))?/?$!) {
    $log->info("Serving new main menu");
    success($stream);
    my $page = $server->{wiki_main_page};
    if ($page) {
      $stream->write(encode_utf8 text($host, $space, $page));
    } else {
      $stream->write("# Welcome to Phoebe!\n");
      $stream->write("\n");
    }
    blog_with_headers($stream, $host, $space, 10);
    return 1;
  }
  return;
}

# The main page includes a blog with the ten most recent blog pages based on the
# filename. When linking to these pages, however, we want to display the name of
# their first header!
sub blog_with_headers {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $n = shift || 10;
  my @blog = blog_pages($host, $space);
  return unless @blog;
  $stream->write("Blog:\n");
  for my $id (@blog[0 .. min($#blog, $n - 1)]) {
    my $text = encode_utf8 text($host, $space, $id);
    next unless $text; # skipping empty pages
    my ($title) = $text =~ /^# (.*)/m;
    $title ||= "(untitled)";
    print_link($stream, $host, $space, $title, "page/$id");
  }
  $stream->write("\n");
}

# When serving a page, we don't want to use the filename as a first level
# heading.
sub serve_page {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $revision = shift;
  $log->info("Serve Gemini page $id without a heading");
  success($stream);
  $stream->write(encode_utf8 text($host, $space, $id, $revision));
  $stream->write(encode_utf8 footer($stream, $host, $space, $id, $revision));
}
