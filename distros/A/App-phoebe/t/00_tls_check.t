# Copyright (C) 2017–2020  Alex Schroeder <alex@gnu.org>
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
use Mojo::IOLoop;
use IO::Socket::SSL;

require './t/cert.pl';

my $address = '127.0.0.1';
my $port = Mojo::IOLoop::Server->generate_port;
my $pid = fork();

END {
  # kill server
  if ($pid) {
    kill 'KILL', $pid or warn "Could not kill server $pid";
  }
}

if (!defined $pid) {
  die "Cannot fork: $!";
} elsif ($pid == 0) {
  Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop() });
  start_server();
} else {
  sleep 1;
  use Test::More;
  query1("Hello1");
  query2("Hello2");
  Mojo::IOLoop->stop();
  done_testing();
}

sub start_server {
  say "This is the server listening on port $port...";
  Mojo::IOLoop->server({
    address => $address,
    port => $port,
    tls => 1,
    tls_cert => 't/cert.pem',
    tls_key  => 't/key.pem',
  } => sub {
    my ($loop, $stream) = @_;
    my $data = { buffer => '', handler => \&handle_request };
    $stream->on(read => sub {
      my ($stream, $bytes) = @_;
      $stream->write("Got '$bytes' from the client\n");
      $stream->close_gracefully();
    });
  });
  # Start event loop if necessary
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
  die "Server shutting down.\n";
}

sub query1 {
  my $query = shift;
  # create client
  Mojo::IOLoop->client({
    address => $address,
    port => $port,
    tls => 1,
    tls_options => {SSL_verify_mode => 0x00}
  } => sub {
    my ($loop, $err, $stream) = @_;
    die "Client creation failed: $err\n" if $err;
    $stream->on(error => sub {
      my ($stream, $err) = @_;
      die "Stream error: $err\n" if $err });
    $stream->on(read => sub {
      my ($stream, $bytes) = @_;
      is($bytes, "Got 'Hello1' from the client\n", "Mojo::IOLoop");
    });
    # Write request
    $stream->write("$query")
  });
  # Start event loop if necessary
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

}

sub query2 {
  my $query = shift;
  my $socket = IO::Socket::SSL->new(
    PeerHost => $address, PeerPort => $port,
    SSL_verify_mode => SSL_VERIFY_NONE);
  $socket->print("$query");
  undef $/; # slurp
  is(<$socket>, "Got 'Hello2' from the client\n", "IO::Socket::SSL");
}
