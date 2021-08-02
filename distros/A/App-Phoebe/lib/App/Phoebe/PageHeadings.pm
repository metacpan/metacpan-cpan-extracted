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

App::Phoebe::PageHeadings - use headings instead of file names

=head1 DESCRIPTION

This extension hides the page name from visitors, unless they start digging.

One the front page, where the last ten pages of your date pages are listed, the
name of the page is replaced with the level one heading of your page.

If you visit a page, the name of the page is similarly replaced with the level
one heading of your page.

There is no configuration. Simply add it to your F<config> file:

    use App::Phoebe::PageHeadings;

Beware the consequences:

Every time somebody visits the main page, the main page itself is read, and the
ten blog pages are also read, in order to look for the headings to use; in some
high traffic situations, this could be problematic.

Every page needs to have a top level heading: the file name is no longer shown
to users.

Opening pages and looking for a top level heading doesn’t do regular parsing,
thus if your first top level heading is actually inside code fences (“```”) it
still gets used.

Beware the limitations:

The code doesn’t do the same for requests over the web.

=cut

package App::Phoebe::PageHeadings;
use App::Phoebe qw(@extensions $server $log port host_regex space_regex success
		   blog_pages text print_link footer);
use Modern::Perl;
use List::Util qw(min);
use Encode qw(encode_utf8);

# Blogging where the first level headers in the page takes precedence over the
# filename.

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
      $stream->write(encode_utf8 text($stream, $host, $space, $page));
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
  my @blog = blog_pages($stream, $host, $space, $n);
  return unless @blog;
  $stream->write("Blog:\n");
  for my $id (@blog[0 .. min($#blog, $n - 1)]) {
    my $text = encode_utf8 text($stream, $host, $space, $id);
    next unless $text; # skipping empty pages
    my ($title) = $text =~ /^# (.*)/m;
    $title ||= "(untitled)";
    print_link($stream, $host, $space, $title, "page/$id");
  }
  $stream->write("\n");
}

# When serving a page, we don't want to use the filename as a first level
# heading.
no warnings 'redefine';
*App::Phoebe::serve_page = \&serve_page;

sub serve_page {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $revision = shift;
  $log->info("Serve Gemini page $id without a heading");
  success($stream);
  $stream->write(encode_utf8 text($stream, $host, $space, $id, $revision));
  $stream->write(encode_utf8 footer($stream, $host, $space, $id, $revision));
}

1;
