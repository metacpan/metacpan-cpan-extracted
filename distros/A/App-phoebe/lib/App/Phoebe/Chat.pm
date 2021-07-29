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

App::Phoebe::Chat - add a Gemini-based chat room for every Phoebe wiki space

=head1 DESCRIPTION

For every wiki space, this creates a Gemini-based chat room. Every chat client
needs two URLs, the "listen" and the "say" URL.

The I<Listen URL> is where you need to I<stream>: as people say things in the
room, these messages get streamed in one endless Gemini document. You might have
to set an appropriate timeout period for your connection for this to work. 1h,
perhaps?

The URL will look something like this:
C<gemini://localhost/do/chat/listen> or
C<gemini://localhost/space/do/chat/listen>

The I<Say URL> is where you post things you want to say: point your client at
the URL, it prompts your for something to say, and once you do, it redirects you
to the same URL again, so you can keep saying things.

The URL will look something like this: C<gemini://localhost/do/chat/say> or
C<gemini://localhost/space/do/chat/say>

Your chat nickname is the client certificate's common name. One way to create a
client certificate that's valid for five years with an appropriate common name:

    openssl req -new -x509 -newkey ec \
    -pkeyopt ec_paramgen_curve:prime256v1 \
    -subj '/CN=Alex' \
    -days 1825 -nodes -out cert.pem -keyout key.pem

There is no configuration. Simply add it to your F<config> file:

    use App::Phoebe::Chat;

As a user, first connect using a client that can stream:

    gemini --cert_file=cert.pem --key_file=key.pem \
      gemini://localhost/do/chat/listen

Then connect with a client that let's you post what you type:

    gemini-chat --cert_file=cert.pem --key_file=key.pem \
      "gemini://localhost/do/chat/say"

=cut

package App::Phoebe::Chat;
use App::Phoebe qw(@extensions @request_handlers $log
		   success result port space host_regex space_regex);
use Modern::Perl '2018';
use Encode qw(decode_utf8 encode_utf8);
use URI::Escape;
use utf8;

# Each chat member is {stream => $stream, host => $host, space => $space, name => $name}
my (@chat_members, @chat_lines);
my $chat_line_limit = 50;

# needs a special handler because the stream never closes
my $spaces = space_regex();
unshift(@request_handlers, '^gemini://([^/?#]*)(?:/$spaces)?/do/chat/listen' => \&chat_listen);

sub chat_listen {
  my $stream = shift;
  my $data = shift;
  $log->debug("Handle chat listen request");
  $log->debug("Discarding " . length($data->{buffer}) . " bytes")
      if $data->{buffer};
  my $url = $data->{request};
  my $hosts = host_regex();
  my $spaces = space_regex();
  my $port = port($stream);
  my ($host, $space);
  if (($host, $space) =
      $url =~ m!^(?:gemini:)?//($hosts)(?::$port)?(?:/($spaces))?/do/chat/listen$!) {
    chat_register($stream, $host, $port, space($stream, $host, $space) || '');
    # don't lose the stream!
  } else {
    result($stream, "59", "Don't know how to handle $url");
    $stream->close_gracefully();
  }
}

sub chat_register {
  my $stream = shift;
  my $host = shift;
  my $port = shift;
  my $space = shift;
  my $name = $stream->handle->peer_certificate('cn');
  if (not $name) {
    result($stream, "60", "You need a client certificate with a common name to listen to this chat");
    $stream->close_gracefully();
    return;
  }
  if (grep { $host eq $_->{host} and $space eq $_->{space} and $name eq $_->{name} } @chat_members) {
    result($stream, "40", "'$name' is already taken");
    $stream->close_gracefully();
    return;
  }
  # 1h timeout
  $stream->timeout(3600);
  # remove from channel members if an error happens
  $stream->on(close => sub { chat_leave($host, $space, $name) });
  $stream->on(error => sub { chat_leave($host, $space, $name) });
  # add myself
  push(@chat_members, { host => $host, space => $space, name => $name, stream => $stream });
  # announce myself
  my @names;
  for (@chat_members) {
    next unless $host eq $_->{host} and $space eq $_->{space} and $name ne $_->{name};
    push(@names, $_->{name});
    $_->{stream}->write(encode_utf8 "$name joined\n");
  }
  # and get a welcome message
  success($stream);
  $stream->write(encode_utf8 "# Welcome to $host" . ($space ? "/$space" : "") . "\n");
  if (@names) {
    $stream->write(encode_utf8 "Other chat members: @names\n");
  } else {
    $stream->write("You are the only one.\n");
  }
  $stream->write("Open the following link in order to say something:\n");
  $stream->write("=> gemini://$host:$port" . ($space ? "/$space" : "") . "/do/chat/say\n");
  my @lines = grep { $host eq $_->{host} and $space eq $_->{space} } reverse @chat_lines;
  if (@lines) {
    $stream->write("Replaying some recent messages:\n");
    $stream->write(encode_utf8 "$_->{name}: $_->{text}\n") for @lines;
    $stream->write(encode_utf8 "Welcome! 🥳🚀🚀\n");
  }
  $log->debug("Added $name to the chat");
}

sub chat_leave {
  my ($host, $space, $name) = @_;
  $log->debug("Disconnected $name");
  # remove the chat member from their particular chat
  @chat_members = grep { not ($host eq $_->{host} and $space eq $_->{space} and $name eq $_->{name}) } @chat_members;
  for (@chat_members) { # for members of the same chat
    next unless $host eq $_->{host} and $space eq $_->{space};
    $_->{stream}->write(encode_utf8 "$name left\n");
  }
}

push(@extensions, \&handle_chat_say);

sub handle_chat_say {
  my $stream = shift;
  my $url = shift;
  my $hosts = host_regex();
  my $spaces = space_regex();
  my $port = port($stream);
  my ($host, $space, $text);
  if (($host, $space, $text) =
      $url =~ m!^gemini://($hosts)(?::$port)?(?:/($spaces))?/do/chat/say(?:\?([^#]*))?$!) {
    process_chat_say($stream, $host, $port, $space || "", $text);
    return 1;
  } elsif ($url =~ m!^gemini://(?:$hosts)(?::$port)?(?:/$spaces)?/do/chat$!) {
    serve_chat_explanation($stream, $url);
    return 1;
  }
  return 0;
}

sub serve_chat_explanation {
  my $stream = shift;
  my $url = shift;
  success($stream);
  $stream->write("# Chat\n");
  $stream->write(
    encode_utf8
    "This server supports a Gemini-based chat. "
    . "If you don't have a dedicated client, you can use two windows of a regular Gemini client. "
    . "Visit the following two URLs. "
    . "The first one allows you “listen” to the channel and the second one allows you to “say” things. "
    . "The connection to the “listen” channel needs a streaming client. "
    . "Use a client certificate with the same common name for both connections.\n");
  $stream->write("=> $url/listen\r\n");
  $stream->write("=> $url/say\r\n");
}

sub process_chat_say {
  my $stream = shift;
  my $host = shift;
  my $port = shift;
  my $space = shift;
  my $text = shift;
  my $name = $stream->handle->peer_certificate('cn');
  if (not $name) {
    result($stream, "60", "You need a client certificate with a common name to talk on this chat");
    return;
  }
  my @found = grep { $host eq $_->{host} and $space eq $_->{space} and $name eq $_->{name} } @chat_members;
  if (not @found) {
    result($stream, "40", "You need to join the chat before you can say anything");
    return;
  }
  if (not $text) {
    result($stream, "10", encode_utf8 "Post to the channel as $name");
    return;
  }
  $text = decode_utf8(uri_unescape($text));
  unshift(@chat_lines, { host => $host, space => $space, name => $name, text => $text });
  splice(@chat_lines, $chat_line_limit); # trim length of history
  # send message
  for (@chat_members) {
    next unless $host eq $_->{host} and $space eq $_->{space};
    $_->{stream}->write(encode_utf8 "$name: $text\n");
  }
  # and ask to send another one
  result($stream, "31", "gemini://$host:$port" . ($space ? "/$space" : "") . "/do/chat/say");
  return;
}

# run every minute and print a timestamp every 5 minutes
Mojo::IOLoop->recurring(60 => sub {
  my $loop = shift;
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
  return unless $min % 5 == 0;
  $log->debug("Chat ping");
  my $ts = sprintf("%02d:%02d UTC\n", $hour, $min);
  for (@chat_members) {
      $_->{stream}->write($ts);
  }});
