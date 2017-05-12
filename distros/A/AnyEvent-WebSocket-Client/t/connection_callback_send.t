use strict;
use warnings;
BEGIN { eval q{ use EV } }
use AnyEvent::WebSocket::Client;
use Test::More tests => 1;
use FindBin ();
use lib $FindBin::Bin;
use testlib::Server;

testlib::Server->set_timeout;

my $uri = testlib::Server->start_echo;
my $done = AnyEvent->condvar;
my $client= AnyEvent::WebSocket::Client->new;
$client->connect($uri)->cb(sub {

  our($connection) = eval { shift->recv };
  if($@)
  {
    diag "error connection: $@";
    return;
  }
  
  $connection->on(next_message =>sub {
    my($connection, $message) = @_;
    $done->send($message->body);
  });
  
  $connection->send("foo");

});

is $done->recv, 'foo';
