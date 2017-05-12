use strict;
use warnings;
use Test::More;
BEGIN { plan skip_all => 'Requires Capture::Tiny' unless eval q{ use Capture::Tiny qw( capture_stderr ); 1 } }
BEGIN { plan skip_all => 'Requires EV' unless eval q{ use EV; 1 } }
BEGIN { plan skip_all => 'Requires Mojolicious 3.0' unless eval q{ use Mojolicious 3.0; 1 } }
BEGIN { plan skip_all => 'Requires Mojolicious::Lite' unless eval q{ use Mojolicious::Lite; 1 } }
BEGIN { plan skip_all => 'Requires Test::Memory::Cycle' unless eval q{ use Test::Memory::Cycle; 1 } }
BEGIN { plan skip_all => 'Requires Devel::Cycle' unless eval q{ use Devel::Cycle; 1 } }
use AnyEvent::WebSocket::Client;
use FindBin;
use lib $FindBin::Bin;
use testlib::Mojo;
use testlib::Server;

testlib::Server->set_timeout;

plan tests => 5;

app->log->level('fatal');

my $finished = 0;

websocket '/foo' => sub {
  my $self = shift;
  $self->on(message => sub {
    my($self, $payload) = @_;
    $self->send($payload);
  });
  $self->on(finish => sub {
    $finished = 1;
    note 'FINISH';
  });
};


my ($server, $port) =  testlib::Mojo->start_mojo(app => app());

my $client = AnyEvent::WebSocket::Client->new;

my $connection = $client->connect("ws://127.0.0.1:$port/foo")->recv;
isa_ok $connection, 'AnyEvent::WebSocket::Connection';

is $finished, 0, 'finished = 0';

$connection->send('foo');

is $finished, 0, 'finished = 0';

note capture_stderr { memory_cycle_ok $connection };
undef $connection;

$server->ioloop->one_tick;
$server->ioloop->one_tick;

is $finished, 1, 'finished = 1';

