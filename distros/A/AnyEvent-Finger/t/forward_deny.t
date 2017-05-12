use strict;
use warnings;
use Test::More tests => 6;
use AnyEvent::Finger::Client;
use AnyEvent::Finger::Server;

my $bind = AnyEvent->condvar;
my $server = eval { 
  AnyEvent::Finger::Server->new( 
    port         => 0, 
    hostname     => '127.0.0.1',
    forward_deny => 1,
    on_bind      => sub { $bind->send },
  );
};
diag $@ if $@;
isa_ok $server, 'AnyEvent::Finger::Server';

eval { $server->start(
  sub {
    my $tx = shift;
    $tx->res->say("okay");
    $tx->res->done;
  }
) };
diag $@ if $@;

$bind->recv;
my $port = $server->bindport;
like $port, qr{^[123456789]\d*$}, "bindport = $port";

my $client = AnyEvent::Finger::Client->new( port => $port, on_error => sub { say STDERR shift; exit 2 } );

subtest "finger" => sub {
  my $done = AnyEvent->condvar;

  my $lines;
  $client->finger('', sub {
    ($lines) = shift;
    $done->send;
  });
  
  $done->recv;
  
  is $lines->[0], 'okay', 'lines[0] == okay';
};


subtest "finger \@localhost" => sub {
  my $done = AnyEvent->condvar;

  my $lines;
  $client->finger('@localhost', sub {
    ($lines) = shift;
    $done->send;
  });
  
  $done->recv;
  
  is $lines->[0], 'finger forwarding service denied', 'lines[0] == finger forwarding service denied';
};

subtest "finger foo\@localhost" => sub {
  my $done = AnyEvent->condvar;

  my $lines;
  $client->finger('foo@localhost', sub {
    ($lines) = shift;
    $done->send;
  });
  
  $done->recv;
  
  is $lines->[0], 'finger forwarding service denied', 'lines[0] == finger forwarding service denied';
};

subtest "finger foo\@bar\@baz\@whatever\@loalhost" => sub {
  my $done = AnyEvent->condvar;

  my $lines;
  $client->finger('foo@bar@baz@whatever@localhost', sub {
    ($lines) = shift;
    $done->send;
  });
  
  $done->recv;
  
  is $lines->[0], 'finger forwarding service denied', 'lines[0] == finger forwarding service denied';
};
