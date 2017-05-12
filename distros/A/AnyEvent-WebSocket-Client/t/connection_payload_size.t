use strict;
use warnings;
BEGIN { eval q{ use EV } }
use AE;
use AnyEvent::WebSocket::Connection;
use Protocol::WebSocket::Frame;
use Test::More;
use FindBin ();
use lib $FindBin::Bin;
use testlib::Server;
use testlib::Connection;

testlib::Server->set_timeout;

my $connection;

{
  my @messages;
  my $message_cv = AE::cv;
  my $handle;

  ($connection, $handle) = testlib::Connection->create_connection_and_handle({ max_payload_size => 65538});
  note "connection.max_payload_size = @{[ $connection->max_payload_size ]}";

  my $frame = Protocol::WebSocket::Frame->new( max_payload_size => 0 );
  $handle->on_read(sub {
    #my($handle) = @_;
    $frame->append($handle->{rbuf});
    while(defined(my $body = $frame->next_bytes))
    {
      push @messages, AnyEvent::WebSocket::Message->new(
        body   => $body,
        opcode => $frame->opcode,
      );
      $message_cv->send;
    }
  });

  sub get_next_message
  {
    $message_cv->recv;
    $message_cv = AE::cv;
    shift @messages;
  }
  
  sub send_message
  {
    my($body,$cb) = @_;
    my $cv = AE::cv;
    if($cb)
    {
      $connection->on(next_message => sub {
        $cb->(@_);
        $cv->send;
      });
    }
    my $frame = Protocol::WebSocket::Frame->new(
      max_payload_size => 0,
      buffer => $body,
    );
    $handle->push_write($frame->to_bytes);
    $cv->recv if $cb;
  }

}

subtest 'send payload with size > 65536' => sub {

  my $data = 'x' x 65537;

  subtest 'plain string' => sub {
    eval { $connection->send($data) };
    is $@, '';
    my $rmessage = get_next_message();
    ok $rmessage;
    is $rmessage->body, $data;
  };
  
  subtest 'message object' => sub {
    my $smessage = AnyEvent::WebSocket::Message->new(
      body => $data,
    );
    eval { $connection->send($smessage) };
    is $@, '';
    my $rmessage = get_next_message();
    ok $rmessage;
    is $rmessage->body, $data;
  };

};

subtest 'receive payload with size > 65536' => sub {

  my $data = 'x' x 65537;

  send_message($data, sub {
  
    my($connection, $message) = @_;
    is $message->body, $data;
  
  });
  
};

subtest 'receieve payload with size > max_payload_size' => sub {

  my $data = 'x' x 65540;
  my $here = 1;
  my $cv = AE::cv;
  
  $connection->on(parse_error => sub {
    my($connection, $error) = @_;
    return unless $here;
    ok $error, "error is: $error";
    $cv->send;
  });
  send_message($data);
  $cv->recv;

  $here = 0;
};

done_testing;
