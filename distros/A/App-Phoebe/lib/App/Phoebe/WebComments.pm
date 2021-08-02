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

App::Phoebe::WebComments - allow comments on a Phoebe wiki via the web

=head1 DESCRIPTION

This extension allows visitors on the web to add comments.

Comments are appended to a "comments page". For every page I<Foo> the comments
are found on I<Comments on Foo>. This prefix is fixed, currently.

On the comments page, each new comment starts with the character LEFT SPEECH
BUBBLE (🗨). This character is fixed, currently.

There is no configuration. Simply add it to your F<config> file:

    use App::Phoebe::WebComments;

=cut

package App::Phoebe::WebComments;
use App::Phoebe qw(@footer @extensions @request_handlers $server $log port space
		    host_regex space_regex quote_html wiki_dir with_lock
		    bogus_hash to_url);
use App::Phoebe::Web qw(handle_http_header http_error);
use Modern::Perl;
use URI::Escape;
use File::Slurper qw(write_text);
use Encode qw(decode_utf8 encode_utf8);
use File::Slurper qw(read_text);
use utf8;

push(@footer, \&add_comment_web_link_to_footer);

sub add_comment_web_link_to_footer {
  my ($self, $host, $space, $id, $revision, $scheme) = @_;
  # only leave comments on current comment pages
  return "" if $revision;
  $space = "/" . uri_escape_utf8($space) if $space;
  $space //= "";
  return "=> $space/page/" . uri_escape_utf8("Comments on $id") . " Comments"
      if $id !~ /^Comments on / and not grep { $_ eq \&add_comment_link_to_footer } @footer;
  return "=> $space/do/comment/" . uri_escape_utf8($id) . " Leave a short comment" if $scheme eq "html";
}

unshift(@request_handlers, '^POST .* HTTP/1\.[01]$' => \&handle_http_header);

push(@extensions, \&process_comment_requests_via_http);

sub process_comment_requests_via_http {
  my ($stream, $url, $headers, $buffer) = @_;
  my $hosts = host_regex();
  my $spaces = space_regex();
  my $port = port($stream);
  my ($host, $space, $id, $token, $query);
  if (($space, $id) = $url =~ m!^GET (?:/($spaces))?/do/comment/([^/#?]+) HTTP/1\.[01]$!
      and ($host) = $headers->{host} =~ m!^($hosts)(?::$port)$!) {
    serve_comment_via_http($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($id)));
    return 1;
  } elsif (($space, $id) = $url =~ m!^POST (?:/($spaces))?/do/comment/([^/#?]+) HTTP/1\.[01]$!
	   and ($host) = $headers->{host} =~ m!^($hosts)(?::$port)$!) {
    append_comment_via_http($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($id)), $buffer);
    return 1;
  }
  return 0;
}

sub serve_comment_via_http {
  my ($stream, $host, $space, $id) = @_;
  $log->info("Serve comments for $id via HTTP");
  $stream->write("HTTP/1.1 200 OK\r\n");
  $stream->write("Content-Type: text/html\r\n");
  $stream->write("\r\n");
  $stream->write("<!DOCTYPE html>\r\n");
  $stream->write("<html>\r\n");
  $stream->write("<head>\r\n");
  $stream->write("<meta charset=\"utf-8\">\r\n");
  $stream->write(encode_utf8 "<title>" . quote_html($id) . "</title>\r\n");
  $stream->write("<link type=\"text/css\" rel=\"stylesheet\" href=\"/default.css\"/>\r\n");
  $stream->write("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\r\n");
  $stream->write("</head>\r\n");
  $stream->write("<body>\r\n");
  $stream->write(encode_utf8 "<h1>" . quote_html($id) . "</h1>\r\n");
  $stream->write("<form method=\"POST\">\r\n");
  $stream->write("<p><label for=\"token\">Token:</label>\r\n");
  $stream->write("<br><input type=\"text\" id=\"token\" name=\"token\" required>\r\n");
  $stream->write("<p><label for=\"comment\">Comment:</label>\r\n");
  $stream->write("<br><textarea style=\"width: 100%; height: 10em;\" id=\"comment\" name=\"comment\" required></textarea>\r\n");
  $stream->write("<p><input type=\"submit\" value=\"Save\">\r\n");
  $stream->write("</form>\r\n");
  $stream->write("</body>\r\n");
  $stream->write("</html>\r\n");
}

sub append_comment_via_http {
  my ($stream, $host, $space, $id, $buffer) = @_;
  $log->info("Save comments for $id via HTTP");
  my %params;
  for (split(/&/, $buffer)) {
    my ($key, $value) = map { s/\+/ /g; decode_utf8(uri_unescape($_)) } split(/=/, $_, 2);
    $params{$key} = $value;
  }
  $log->debug("Parameters: " . join(", ", map { "$_ => '$params{$_}'" } keys %params));
  my $token = quotemeta($params{token}||"");
  my @tokens = @{$server->{wiki_token}};
  push(@tokens, @{$server->{wiki_space_token}->{$space}})
      if $space and $server->{wiki_space_token}->{$space};
  return http_error($stream, "Token required") if not $token and @tokens;
  return http_error($stream, "Wrong token") if not grep(/^$token$/, @tokens);
  my $comment = $params{comment};
  return http_error($stream, "Comment required") if not $comment;
  my $dir = wiki_dir($host, $space);
  my $file = "$dir/page/$id.gmi";
  my $text;
  if (-e $file) {
    $text = read_text($file) . "\n\n🗨 " . $comment;
  } else {
    $text = $comment;
  }
  with_lock($stream, $host, $space, sub { write_page_for_http($stream, $host, $space, $id, $text) } );
}

sub write_page_for_http {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $text = shift;
  $log->info("Writing page $id");
  my $dir = wiki_dir($host, $space);
  my $file = "$dir/page/$id.gmi";
  my $revision = 0;
  if (-e $file) {
    my $old = read_text($file);
    if ($old eq $text) {
      $log->info("$id is unchanged");
      my $message = to_url($stream, $host, $space, "page/$id", "https");
      $stream->write("HTTP/1.1 302 Found\r\n");
      $stream->write("Location: $message\r\n");
      $stream->write("\r\n");
      return;
    }
    mkdir "$dir/keep" unless -d "$dir/keep";
    if (-d "$dir/keep/$id") {
      foreach (read_dir("$dir/keep/$id")) {
	$revision = $1 if m/^(\d+)\.gmi$/ and $1 > $revision;
      }
      $revision++;
    } else {
      mkdir "$dir/keep/$id";
      $revision = 1;
    }
    rename $file, "$dir/keep/$id/$revision.gmi";
  } else {
    my $index = "$dir/index";
    if (not open(my $fh, ">>:encoding(UTF-8)", $index)) {
      $log->error("Cannot write index $index: $!");
      return http_error($stream, "Unable to write index");
    } else {
      say $fh $id;
      close($fh);
    }
  }
  my $changes = "$dir/changes.log";
  if (not open(my $fh, ">>:encoding(UTF-8)", $changes)) {
    $log->error("Cannot write log $changes: $!");
    return http_error($stream, "Unable to write log");
  } else {
    my $peerhost = $stream->handle->peerhost;
    say $fh join("\x1f", scalar(time), $id, $revision + 1, bogus_hash($peerhost));
    close($fh);
  }
  mkdir "$dir/page" unless -d "$dir/page";
  eval { write_text($file, $text) };
  if ($@) {
    $log->error("Unable to save $id: $@");
    return http_error($stream, "Unable to save $id");
  } else {
    $log->info("Wrote $id");
    my $message = to_url($stream, $host, $space, "page/$id", "https");
    $stream->write("HTTP/1.1 302 Found\r\n");
    $stream->write("Location: $message\r\n");
    $stream->write("\r\n");
  }
}

1;
