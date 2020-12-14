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

our (@footer, @extensions, @request_handlers, @main_menu, $server, $log);

unshift(@request_handlers, '^POST .* HTTP/1\.[01]$' => \&handle_http_header);

# edit from the web

push(@footer, \&add_edit_link_to_footer);

sub is_editable {
  my ($space) = @_;
  my $editable = { return test => 1, gemini => 1 };
  return $editable->{$space};
}

sub add_edit_link_to_footer {
  my ($stream, $host, $space, $id, $revision, $format) = @_;
  # only add the edit links to the web UI of the test space
  # return if not $space or not is_editable($space);
  return "" if $revision or not $id or $format ne "html";
  $id = uri_escape_utf8($id);
  if ($space) {
    $space = uri_escape_utf8($space);
    return "=> /$space/do/edit/$id Edit";
  } else {
    return "=> /do/edit/$id Edit";
  }
}

push(@extensions, \&process_edit_requests);

sub process_edit_requests {
  my ($stream, $request, $headers, $buffer) = @_;
  my $host_regex = host_regex();
  my $spaces = space_regex();
  my $port = port($stream);
  my ($host, $space, $id, $token, $query);
  if (($space, $id) = $request =~ m!^GET (?:/($spaces))?/do/edit/([^/#?]+) HTTP/1\.[01]$!
      and is_editable($space)
      and ($host) = $headers->{host} =~ m!^($host_regex)(?::$port)$!) {
    serve_edit_via_http($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($id)));
  } elsif (($space, $id) = $request =~ m!^POST (?:/($spaces))?/do/edit/([^/#?]+) HTTP/1\.[01]$!
	   and is_editable($space)
	   and ($host) = $headers->{host} =~ m!^($host_regex)(?::$port)$!) {
    save_edit_via_http($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($id)), $headers, $buffer);
  } else {
    return 0;
  }
  return 1;
}

sub serve_edit_via_http {
  my ($stream, $host, $space, $id) = @_;
  $log->info("Serve edit page for $id via HTTP");
  $stream->write("HTTP/1.1 200 OK\r\n");
  $stream->write("Content-Type: text/html\r\n");
  $stream->write("\r\n");
  $stream->write("<!DOCTYPE html>\n");
  $stream->write("<html>\n");
  $stream->write("<head>\n");
  $stream->write("<meta charset=\"utf-8\">\n");
  $stream->write(encode_utf8 "<title>" . quote_html($id) . "</title>\n");
  $stream->write("<link type=\"text/css\" rel=\"stylesheet\" href=\"/default.css\"/>\n");
  $stream->write("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
  $stream->write("</head>\n");
  $stream->write("<body>\n");
  $stream->write("<h1>" . quote_html($id) . "</h1>\n");
  $stream->write("<form method=\"POST\">\n");
  $stream->write("<p><label for=\"token\">Token:</label>\n");
  $stream->write("<br><input type=\"text\" id=\"token\" name=\"token\" required>\n");
  $stream->write("<p><label for=\"text\">Text:</label>\n");
  my $text = text($host, $space, $id);
  # textarea can be empty in order to delete a page
  $stream->write(encode_utf8 "<br><textarea style=\"width: 100%; height: 20em;\" id=\"text\" name=\"text\">$text</textarea>\n");
  $stream->write("<p><input type=\"submit\" value=\"Save\">\n");
  $stream->write("</form>\n");
  $stream->write("</body>\n");
  $stream->write("</html>\n");
}

sub save_edit_via_http {
  my ($stream, $host, $space, $id, $headers, $buffer) = @_;
  $log->info("Save edit for $id via HTTP");
  return http_error($stream, "Page name is missing") unless $id;
  return http_error($stream, "Page names must not control characters") if $id =~ /[[:cntrl:]]/;
  return http_error($stream, "Content type not known")
      if not $headers->{"content-type"} or $headers->{"content-type"} ne "application/x-www-form-urlencoded";
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
  my $text = $params{text}||"";
  $text =~ s/\r\n/\n/g; # fix DOS EOL convention
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
