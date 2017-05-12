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

testlib::Server->set_timeout();

note(<<ENDNOTE);
Connection should shutdown its socket when the peer shuts down.
This is because in some cases the socket is still half-open (writable)
when it detects the shutdown from its peer. If it remains half-open,
the peer never gets EOF on its reading socket.
ENDNOTE

sub test_case
{
  my ($label, $code) = @_;
  subtest $label, sub {
    my ($a_conn, $b_handle) = testlib::Connection->create_connection_and_handle();

    my $cv_finish = AnyEvent->condvar;
    $cv_finish->begin;
    $cv_finish->begin;
    $a_conn->on(finish => sub { $cv_finish->end });
    $b_handle->on_read(sub {});
    $b_handle->on_eof(sub { $cv_finish->end });
    $code->($a_conn, $b_handle);
    $cv_finish->recv;
    pass "OK";
  };
}

test_case "on_eof of a_conn", sub {
  my ($a_conn, $b_handle) = @_;
  $b_handle->push_shutdown();
};

test_case "on_error of a_conn", sub {
  my ($a_conn, $b_handle) = @_;
  
  # force connection error on a_conn
  $a_conn->handle->push_shutdown;
  $a_conn->send("foo");
  $a_conn->send("bar");
};

done_testing;
