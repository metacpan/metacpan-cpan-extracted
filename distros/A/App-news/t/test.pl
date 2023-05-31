# Copyright (C) 2017–2023  Alex Schroeder <alex@gnu.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use Modern::Perl;
use Test::More;
use File::Slurper qw(read_text read_dir);
use Mojo::IOLoop;
use File::Copy;
use Encode;
use Encode::Locale;

our $port = Mojo::IOLoop::Server->generate_port;
our $pid = fork();

END {
  # kill server
  if ($pid) {
    kill 'KILL', $pid or warn "Could not kill server $pid";
  }
}

sub process {
  my ($stream, $line) = @_;
  if ($line =~ /^quit$/i) {
    $stream->write("205 goodbye.\r\n" => sub { $stream->close_gracefully });
  } elsif ($line =~ /^mode reader$/i) {
    $stream->write("200 posting allowed.\r\n");
  } elsif ($line =~ /^list$/i) {
    $stream->write("215 list of newsgroups follows\r\n");
    $stream->write("local.test 2 1 y\r\n");
    $stream->write(".\r\n");
  } elsif ($line =~ /^LIST NEWSGROUPS local\.test$/i) {
    $stream->write("215 list of newsgroups follows\r\n");
    $stream->write("local.test Testing\r\n");
    $stream->write(".\r\n");
  } elsif ($line =~ /^GROUP local\.test$/i) {
    $stream->write("211 2 1 2 local.test\r\n");
  } elsif ($line =~ /^LIST OVERVIEW.FMT$/i) {
    $stream->write("215 list of fields follows\r\n");
    $stream->write("Subject:\r\n");
    $stream->write("From:\r\n");
    $stream->write("Date:\r\n");
    $stream->write("Message-ID:\r\n");
    $stream->write("References:\r\n");
    $stream->write(":bytes\r\n");
    $stream->write(":lines\r\n");
    $stream->write(".\r\n");
  } elsif ($line =~ /^XOVER 1-2$/i) {
    $stream->write("224 Overview information follows\r\n");
    $stream->write("1\tHaiku\tPoet <poet\@example.com>\t6 Oct 1998 04:38:40 -0500\t<1\@example.com>\t\t73\t3\r\n");
    $stream->write("2\tRe: Haiku\tBard <bard\@example.com>\t6 Oct 1998 05:38:40 -0500\t<2\@example.com>\t<1\@example.net>\t1234\t17\r\n");
    $stream->write(".\r\n");
  } elsif ($line =~ /^ARTICLE 1$/i) {
    $stream->write("220 1 <1\@example.com>\r\n");
    $stream->write("Path: pathost!demo!whitehouse!not-for-mail\r\n");
    $stream->write("From: Poet <poet\@example.net>\r\n");
    $stream->write("Newsgroups: local.test\r\n");
    $stream->write("Subject: Haiku\r\n");
    $stream->write("Date: 6 Oct 1998 04:38:40 -0500\r\n");
    $stream->write("Message-ID: <1\@example.com>\r\n");
    $stream->write("\r\n");
    $stream->write("Tin is my reader\r\n");
    $stream->write("A program from the nineties\r\n");
    $stream->write("Church bells are ringing\r\n");
    $stream->write(".\r\n");
  } else {
    diag("Unhandled: $line");
  }
}

if (!defined $pid) {
  die "Cannot fork: $!";
} elsif ($pid == 0) {
  diag "This is the News server listening on port $port...";
  my $buffer;
  my $server = Mojo::IOLoop->server({port => $port} => sub {
    my ($loop, $stream, $id) = @_;
    diag "Accepted connection";
    $stream->write("200 test server ready - posting ok\r\n");
    $stream->on(read => sub {
      my ($stream, $bytes) = @_;
      diag "Received $bytes";
      $buffer .= $bytes;
      while ($buffer =~ /(.*?)\r\n/) {
        process($stream, $1);
        $buffer = substr($buffer, length($1) + 2);
      }})});
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
  diag "News server on port $port shutting down";
  exit 0;
}

# test client must wait for the server to start up
sleep 1;

1;
