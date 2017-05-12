use strict;
use warnings;
BEGIN { eval q{ use EV } }
use AnyEvent::WebSocket::Client;
use Test::More;
use FindBin ();
use lib $FindBin::Bin;
use testlib::Server;

testlib::Server->set_timeout;

my $uri = testlib::Server->start_echo;

my $client = AnyEvent::WebSocket::Client->new( max_payload_size => 65538 );

subtest 'connection gets same max_payload_size as client' => sub {

  my $connection = $client->connect($uri)->recv;
  is $connection->max_payload_size, 65538;

};

subtest 'send message > 65536' => sub {

  my $data = 'x' x 65537;
  
  my $connection = $client->connect($uri)->recv;
  
  my $cv = AE::cv;
  $connection->on(next_message => sub {
    my($connection, $message) = @_;
    is $message->body, $data;
    $cv->send;
  });
  
  eval { $connection->send($data) };
  is $@, '';
  
  $cv->recv;
  
};

# test the double standard that we can send any sized
# frame, but will not accept large ones.
subtest 'receive message > max_payload_size' => sub {

  my $data = 'x' x 65540;
  
  my $connection = $client->connect($uri)->recv;
  
  my $cv = AE::cv;
  $connection->on(parse_error => sub {
    my($connection, $error) = @_;
    isnt $error, '', "Error is: $error";
    $cv->send;
  });
  
  eval { $connection->send($data) };
  is $@, '';
  
  $cv->recv;

};

done_testing;
