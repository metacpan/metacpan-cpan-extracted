use strict;
use warnings;
BEGIN { eval q{ use EV } }
use Test::More;
use AnyEvent;
use AnyEvent::WebSocket::Connection;
use FindBin ();
use lib $FindBin::Bin;
use testlib::Server;
use testlib::Connection;
use Protocol::WebSocket::Frame;

note("Connection should respond to a ping frame with a pong frame.");

testlib::Server->set_timeout;

my ($a_conn, $b_handle) = testlib::Connection->create_connection_and_handle();

my $parser = Protocol::WebSocket::Frame->new;
my $cv_finish = AnyEvent->condvar;
$b_handle->on_read(sub {
  my ($handle) = @_;
  $parser->append($handle->{rbuf});
  my $payload = $parser->next_bytes;
  return if !defined($payload);
  is $parser->opcode, 10, "pong frame received";
  is $payload, "foobar", "... payload is identical to what b_handle has sent.";
  $cv_finish->send;
});
$b_handle->push_write(Protocol::WebSocket::Frame->new(type => "ping", buffer => "foobar")->to_bytes);

$cv_finish->recv;

done_testing;
