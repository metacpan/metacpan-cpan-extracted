use strict;
use warnings;
use AnyEvent::WebSocket::Client;
use Test::More;
BEGIN { plan skip_all => 'Requires IO::Socket::SSL 1.75' unless eval q{ use IO::Socket::SSL 1.75; 1 } }
BEGIN { plan skip_all => 'Requires EV' unless eval q{ use EV; 1 } }
BEGIN { plan skip_all => 'Requires Mojolicious 3.0' unless eval q{ use Mojolicious 3.0; 1 } }
BEGIN { plan skip_all => 'Requires Mojolicious::Lite' unless eval q{ use Mojolicious::Lite; 1 } }
use FindBin;
use lib $FindBin::Bin;
use testlib::Mojo;
use testlib::Server;

if($Mojolicious::VERSION eq '4.47' && $IO::Socket::SSL::VERSION >= 1.955 && $Net::SSLeay::VERSION < 1.56)
{
  plan skip_all => 'Combination of Mojolicious == 4.47, IO::Socket::SSL >= 1.955 and Net::SSLeay < 1.56 breaks this test';
}

testlib::Server->set_timeout;

plan skip_all => 'set ANYEVENT_WEBSOCKET_CLIENT_TEST_MOJO_SSL to enable this test'
  unless $ENV{ANYEVENT_WEBSOCKET_CLIENT_TEST_MOJO_SSL};

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

my ($server, $port) =  testlib::Mojo->start_mojo(app => app(), ssl => 1);

my $client = AnyEvent::WebSocket::Client->new( ssl_no_verify => 1 );

my $connection = $client->connect("wss://127.0.0.1:$port/count/10")->recv;
isa_ok $connection, 'AnyEvent::WebSocket::Connection';

my $done = AnyEvent->condvar;

$connection->send('ping');

my $last;

$connection->on(each_message => sub {
  my $message = pop->decoded_body;
  note "recv $message";
  $connection->send('ping');
  $last = $message;
});

$connection->on(finish => sub {
  $done->send(1);
});

is $done->recv, '1', 'friendly disconnect';

is $last, 9, 'last = 9';

