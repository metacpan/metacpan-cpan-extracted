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

note("Connection should not send after sending close frame, should not receive after receiving close frame");

sub make_frame {
  return Protocol::WebSocket::Frame->new(@_)->to_bytes;
}

testlib::Server->set_timeout;

subtest "it should not send after sending close frame", sub {
  my ($a_conn, $b_handle) = testlib::Connection->create_connection_and_handle();

  my $b_received;
  my $cv_finish = AnyEvent->condvar;
  $cv_finish->begin;
  $cv_finish->begin;
  $b_handle->on_read(sub { });
  $b_handle->on_error(sub {
    $b_received = $_[0]->{rbuf};
    $_[0]->{rbuf} = "";
    $cv_finish->end;
  });
  $a_conn->on(finish => sub {
    $cv_finish->end;
  });
  $a_conn->close();
  $a_conn->send("hoge");
  $cv_finish->recv;

  my $parser = Protocol::WebSocket::Frame->new();
  $parser->append($b_received);
  ok defined($parser->next_bytes), "received a complete frame";
  ok $parser->is_close, "... and it's a close frame";
  ok !defined($parser->next_bytes), "no more frame";
};

subtest "it should not receive after receiving close frame", sub {
  my ($a_conn, $b_handle) = testlib::Connection->create_connection_and_handle();

  my @received_messages = ();
  my $cv_finish = AnyEvent->condvar;
  $a_conn->on(each_message => sub { push(@received_messages, $_[1]) });
  $a_conn->on(finish => sub { $cv_finish->send });
  $b_handle->push_write(make_frame(type => "close"));
  $b_handle->push_write(make_frame(buffer => "hoge"));
  $b_handle->push_shutdown;
  $cv_finish->recv;
  is scalar(@received_messages), 0, "the message 'hoge' should be discarded"
      or diag($received_messages[0]->body);
};

done_testing;
