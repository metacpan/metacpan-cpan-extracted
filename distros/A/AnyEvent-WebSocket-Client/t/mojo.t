use strict;
use warnings;
use AnyEvent::WebSocket::Client;
use Test::More;
BEGIN { plan skip_all => 'Requires EV' unless eval q{ use EV; 1 } }
BEGIN { plan skip_all => 'Requires Mojolicious 3.0' unless eval q{ use Mojolicious 3.0; 1 } }
BEGIN { plan skip_all => 'Requires Mojolicious::Lite' unless eval q{ use Mojolicious::Lite; 1 } }
use FindBin;
use lib $FindBin::Bin;
use testlib::Mojo;
use testlib::Server;

testlib::Server->set_timeout;

plan tests => 3;

app->log->level('fatal');

websocket '/count/:num' => sub {
  my($self) = shift;

  my $max = $self->param('num');
  my $counter = 1;
  
  $self->on(message => sub {
   my($self, $payload) = @_;
     note "send $counter";
     $self->send($counter++);
     if($counter >= $max)
     {
       $self->finish;
     }
  });
};

my ($server, $port) = testlib::Mojo->start_mojo(app => app());

my $client = AnyEvent::WebSocket::Client->new;

my $connection = $client->connect("ws://127.0.0.1:$port/count/10")->recv;
isa_ok $connection, 'AnyEvent::WebSocket::Connection';

my $done = AnyEvent->condvar;

$connection->send('ping');

my $last;

$connection->on(each_message => sub {
  my $message = pop->body;
  note "recv $message";
  $connection->send('ping');
  $last = $message;
});

$connection->on(finish => sub {
  $done->send(1);
});

is $done->recv, '1', 'friendly disconnect';

is $last, 9, 'last = 9';

