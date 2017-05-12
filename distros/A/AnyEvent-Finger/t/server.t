use strict;
use warnings;
use Test::More tests => 6;
use AnyEvent::Finger::Client;
use AnyEvent::Finger::Server;

my $bind;

my $server = eval { 
  AnyEvent::Finger::Server->new( 
    port     => 0, 
    hostname => '127.0.0.1',
    on_bind  => sub { $bind->send },
  );
};
diag $@ if $@;
isa_ok $server, 'AnyEvent::Finger::Server';

eval { 
  $bind = AnyEvent->condvar;
  $server->start(
    sub {
      my $tx = shift;
      my $req = $tx->req;
      eval {
        $tx->res->say("request = '$req'");
        $tx->res->say($tx->remote_port);
        $tx->res->say($tx->local_port);
        $tx->res->say($tx->remote_address);
      };
      diag $@ if $@;
      $tx->res->done;
    }
  );
  $bind->recv;
};
diag $@ if $@;

my $port = $server->bindport;
like $port, qr{^[123456789]\d*$}, "bindport = $port";

my $client = AnyEvent::Finger::Client->new( port => $port, on_error => sub { say STDERR shift; exit 2 } );

subtest t1 => sub {
  my $done = AnyEvent->condvar;

  my $lines;
  $client->finger('', sub {
    ($lines) = shift;
    $done->send;
  });
  
  $done->recv;
  
  is $lines->[0], "request = ''", 'response is correct';
  like $lines->[1], qr/^[1-9]\d*$/, "remote_port = " . $lines->[1];
  is $lines->[2], $port, "local_port = " . $port;
  is $lines->[3], '127.0.0.1', 'remote_address = 127.0.0.1';
};

subtest t2 => sub {
  my $done = AnyEvent->condvar;

  my $lines;
  $client->finger('grimlock', sub {
    $lines = shift;
    $done->send;
  });
  
  $done->recv;
  
  is $lines->[0], "request = 'grimlock'", 'response is correct';
};

eval {
  $server->stop;
  $bind = AnyEvent->condvar;
  $server->start(sub {
    my $tx = shift;
    $tx->res->say(
      "request_isa: " . ref($tx->req),
      "verbose:     " . $tx->req->verbose,
      "username:    " . $tx->req->username,
      "hostnames:   " . join("@", @{ $tx->req->hostnames }),
    );
    $tx->res->done;
  });
  $bind->recv;
};
diag $@ if $@;

$port = $server->bindport;
like $port, qr{^[123456789]\d*$}, "bindport = $port";
$client = AnyEvent::Finger::Client->new( port => $port, on_error => sub { say STDERR shift; exit 2 } );

subtest t3 => sub {
  my $done = AnyEvent->condvar;
  
  my $lines;
  $client->finger('/W grimlock@localhost@foo@bar@baz', sub {
    $lines = shift;
    $done->send;
  });
  
  $done->recv;
  
  # request_isa: AnyEvent::Finger::Request
  # verbose:     1
  # username:    grimlock
  # hostnames:   localhost@foo@bar@baz

  is $lines->[0], 'request_isa: AnyEvent::Finger::Request';
  is $lines->[1], 'verbose:     1';
  is $lines->[2], 'username:    grimlock';
  is $lines->[3], 'hostnames:   localhost@foo@bar@baz';
};
