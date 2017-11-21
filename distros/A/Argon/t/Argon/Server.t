use Test2::Bundle::Extended;
use AnyEvent;
use Argon::Test;
use Argon::Constants qw(:commands);
use Argon::Message;
use Argon::Server;
use Argon::Client;
use Data::Dumper;

ar_test 'new' => sub{
  my $done = shift;

  ok my $server = Argon::Server->new(key => 'fnord'), 'new';
  $server->start;

  ok $server->addr, 'address';

  my $client_connected = AnyEvent->condvar;
  my $notified = AnyEvent->condvar;

  my $client = Argon::Client->new(
    port   => $server->port,
    host   => $server->host,
    key    => 'fnord',
    ready  => $client_connected,
    notify => $notified,
  );

  $client_connected->recv;
  $client->ping;

  ok $notified->recv, 'ping';
};

done_testing;
