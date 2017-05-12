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
use Protocol::WebSocket 0.13;  # 0.13 required to use "fin" attribute in Frame.
use Protocol::WebSocket::Frame;

note("Connection should refuse extremely huge messages.");

subtest "Connection should refuse huge frames", sub {
  my ($a_conn, $b_handle) = testlib::Connection->create_connection_and_handle();
  my $cv_finish = AnyEvent->condvar;
  $cv_finish->begin;
  $cv_finish->begin;
  my @received_messages = ();
  $a_conn->on(finish => sub {
    $cv_finish->end;
  });
  $a_conn->on(each_message => sub {
    push(@received_messages, $_[1]);
  });
  $b_handle->on_error(sub {
    my $handle = shift;
    $handle->push_shutdown;
    $cv_finish->end;
  });
  $b_handle->on_read(sub { });

  my $frame_header = pack("H*", "827f00000000ffffffff"); # frame payload size = 2**32 - 1 bytes
  my $MAX_SEND_PAYLOAD = 1024; # for safety
  my $count_send_payload = 0;
  $b_handle->push_write($frame_header);
  $b_handle->on_drain(sub {
    my $handle = shift;
    $count_send_payload++;
    if($count_send_payload >= $MAX_SEND_PAYLOAD)
    {
      fail("Connection should be aborted by now.");
      $handle->on_drain(undef);
      $handle->push_shutdown;
      $cv_finish->send;
      return;
    }
    
    # push_write is delayed to prevent deep-recursion and to give
    # $a_conn chance to receive data.
    my $w; $w = AnyEvent->idle(cb => sub {
      undef $w;
      $handle->push_write("A" x 256);
    });
  });
  $cv_finish->recv;

  is scalar(@received_messages), 0, "the frame is too huge to receive.";
};


subtest "Connection should refuse messages with too many fragments", sub {
  my ($a_conn, $b_handle) = testlib::Connection->create_connection_and_handle;
  my $cv_finish = AnyEvent->condvar;
  $cv_finish->begin;
  $cv_finish->begin;
  my @received_messages = ();
  $a_conn->on(finish => sub {
    $cv_finish->end;
  });
  $a_conn->on(each_message => sub {
    push(@received_messages, $_[1])
  });
  $b_handle->on_error(sub {
    my $handle = shift;
    $handle->push_shutdown;
    $cv_finish->end;
  });
  $b_handle->on_read(sub {});

  my $MAX_SEND_FRAMES = 10000;
  my $count_send_frame = 0;
  $b_handle->push_write(Protocol::WebSocket::Frame->new(fin => 0, opcode => 1, buffer => "A")->to_bytes);
  $b_handle->on_drain(sub {
    my $handle = shift;
    $count_send_frame++;
    if($count_send_frame >= $MAX_SEND_FRAMES)
    {
      fail("Connection should be aborted by now.");
      $handle->on_drain(undef);
      $handle->push_shutdown;
      $cv_finish->send;
      return;
    }
    my $w; $w = AnyEvent->idle(cb => sub {
      undef $w;
      $handle->push_write(Protocol::WebSocket::Frame->new(fin => 0, opcode => 0, buffer => "A")->to_bytes);
    });
  });
  $cv_finish->recv;

  is scalar(@received_messages), 0, "the message consists of too many fragments to receive.";
};

done_testing;
