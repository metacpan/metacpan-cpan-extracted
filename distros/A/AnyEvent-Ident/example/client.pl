use strict;
use warnings;
use AnyEvent;
use AnyEvent::Ident::Client;

my $server_port = shift;
$server_port = '1' unless defined $server_port;
my $client_port = shift;
my $client_port = '1' unless defind $client_port;

my $client = AnyEvent::Ident::Client->new( hostname => '127.0.0.1' );

my $done = AnyEvent->condvar;

$client->ident($server_port, $client_port, sub {
  my $response = shift;
  if($response->is_success)
  {
    printf "user: %s os: %s\n", $response->username, $response->os
  }
  else
  {
    printf STDERR "ERROR: %s\n", $response->error_type;
  }
  $done->send;
});

$done->recv;

