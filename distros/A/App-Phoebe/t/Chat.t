# Copyright (C) 2021  Alex Schroeder <alex@gnu.org>
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
use IPC::Open2;
use Encode qw(encode_utf8);

our @use = qw(Chat);

plan skip_all => 'Contributions are an author test. Set $ENV{TEST_AUTHOR} to a true value to run.' unless $ENV{TEST_AUTHOR};

require './t/test.pl';

# variables set by test.pl
our $base;
our $host;
our $port;

my $chat_url = "$base/do/chat";
my $listen_url = "$chat_url/listen";
my $say_url = "$chat_url/say";

like(query_gemini($chat_url), qr/^20/, "# Chat");
like(query_gemini($say_url), qr/^40/, "Need to join chat");

my @tests = ("^# Welcome to localhost" => "test",
	     "^localhost: test" => "hallo",
             "^localhost: hallo");
Mojo::IOLoop->client({
  address => $host,
  port => $port,
  tls => 1,
  tls_cert => "t/cert.pem",
  tls_key => "t/key.pem",
  tls_options => { SSL_verify_mode => 0x00 }} => sub {
    my ($loop, $err, $stream) = @_;
    $stream->on(read => sub {
      my ($stream, $bytes) = @_;
      my $text = encode_utf8 $bytes;
      warn $text if $ENV{TEST_VERBOSE};
      # test something
      my $re = shift(@tests);
      like($text, qr/$re/m, $re) if $re;
      my $response = shift(@tests);
      query_gemini("$say_url?$response") if $response;
      Mojo::IOLoop->stop_gracefully unless @tests;
    });
    # Write request to the server
    $stream->write("$listen_url\r\n")});

# Start event loop if necessary
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

done_testing(5);
