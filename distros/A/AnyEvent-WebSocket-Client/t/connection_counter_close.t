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

testlib::Server->set_timeout();

note("Connection should respond with close frame to close frame");

my ($a_conn, $b_handle) = testlib::Connection->create_connection_and_handle();

my $cv_b_recv = AnyEvent->condvar;
$b_handle->on_error(sub {
  my $h = shift;
  $cv_b_recv->send($h->{rbuf});
  $h->{rbuf} = "";
});
$b_handle->on_read(sub {});
$b_handle->push_write(Protocol::WebSocket::Frame->new(buffer => "", type => "close")->to_bytes);

my $b_recv = $cv_b_recv->recv;
my $parser = Protocol::WebSocket::Frame->new;
$parser->append($b_recv);
ok defined($parser->next_bytes), "received a complete frame";
ok $parser->is_close, "... and it's a close frame";

done_testing;
