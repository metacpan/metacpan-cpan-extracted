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

note("masked attribute should control whether the frames sent by the Connection are masked or not.");

testlib::Server->set_timeout;

foreach my $masked (0, 1)
{
  subtest "masked = $masked", sub {
    my ($a_conn, $b_handle) = testlib::Connection->create_connection_and_handle({masked => $masked});
    my $cv_finish = AnyEvent->condvar;
    $b_handle->on_read(sub {
      my ($handle) = @_;
      return if length($handle->{rbuf}) < 2;
      is substr($handle->{rbuf}, 0, 2), pack("C*", 0x81, ($masked ? 0x85 : 0x05)), "frame header OK";
      $cv_finish->send;
    });
    $a_conn->send("Hello");
    $cv_finish->recv;
  };
}

done_testing;
