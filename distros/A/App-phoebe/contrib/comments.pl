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
use utf8;

our (@footer, @extensions, $log);

push(@footer, \&add_comment_link_to_footer);

sub add_comment_link_to_footer {
  my ($stream, $host, $space, $id, $revision, $scheme) = @_;
  # only leave comments on current comment pages
  return "" if $revision;
  $space = "/" . uri_escape_utf8($space) if $space;
  $space //= "";
  return "=> $space/page/" . uri_escape_utf8("Comments on $id") . " Comments" if $id !~ /^Comments on /;
  return "=> $space/do/comment/" . uri_escape_utf8($id) . " Leave a short comment" if $scheme eq "gemini";
}

push(@extensions, \&process_comment_requests);

sub process_comment_requests {
  my ($stream, $url) = @_;
  my $hosts = host_regex();
  my $spaces = space_regex();
  my $port = port($stream);
  my ($host, $space, $id, $token, $query);
  if ($url =~ m!^gemini://($hosts)(?::$port)?(?:/($spaces))?/do/comment/([^/#?]+)$!) {
    $stream->write("10 Access token\r\n");
  } elsif (($host, $space, $id, $token) =
	   $url =~ m!^gemini://($hosts)(?::$port)?(?:/($spaces))?/do/comment/([^/#?]+)\?([^#]+)!) {
    if ($space) {
      $stream->write("30 gemini://$host:$port/$space/do/comment/$id/$token\r\n");
    } else {
      $stream->write("30 gemini://$host:$port/do/comment/$id/$token\r\n");
    }
  } elsif ($url =~ m!^gemini://($hosts)(?::$port)?(?:/($spaces))?/do/comment/([^/#?]+)/([^/#?]+)$!) {
    $stream->write("10 Short comment\r\n");
  } elsif (($host, $space, $id, $token, $query) = $url =~ m!^gemini://($hosts)(?::$port)?(?:/($spaces))?/do/comment/([^/#?]+)/([^/#?]+)\?([^#]+)!) {
    append_comment($stream, $host, space($host, $space), map { decode_utf8(uri_unescape($_)) } $id, $token, $query);
  } else {
    return 0;
  }
  return 1;
}

sub append_comment {
  my ($stream, $host, $space, $id, $token, $query) = @_;
  return if not valid_id($stream, $host, $space, $id);
  return if not valid_token($stream, $host, $space, $id, {token => $token});
  $log->info("Reading page $id and appending comment");
  my $dir = wiki_dir($host, $space);
  my $file = "$dir/page/$id.gmi";
  my $text;
  if (-e $file) {
    $text = read_text($file) . "\n\n🗨 " . $query;
  } else {
    $text = $query;
  }
  with_lock($stream, $host, $space, sub { write_page($stream, $host, $space, $id, $text) } );
}
