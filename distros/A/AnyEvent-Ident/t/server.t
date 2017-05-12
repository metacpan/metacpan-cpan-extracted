use strict;
use warnings;
use Test::More tests => 25;
use AnyEvent::Ident::Client;
use AnyEvent::Ident::Server;

our $timeout = AnyEvent->timer( 
  after => 10,
  cb    => sub { diag "TIMEOUT"; exit },
);

my $bind;
my $server = eval { AnyEvent::Ident::Server->new( hostname => '127.0.0.1', port => 0, on_bind => sub { $bind->send } ) };
isa_ok $server, 'AnyEvent::Ident::Server';

eval {
  $bind = AnyEvent->condvar;
  $server->start(sub {
    my $tx = shift;
    if($tx->req->server_port == 400
    && $tx->req->client_port == 500)
    {
      $tx->reply_with_user('UNIX', 'grimlock');
    }
    else
    {
      $tx->reply_with_error('NO-USER');
    }
  });
  $bind->recv;
};
diag $@ if $@;

like $server->bindport, qr/^[123456789]\d*$/, "bind port = " . $server->bindport;

my $w = AnyEvent->timer( after => 5, cb => sub { diag "TIMEOUT"; exit } );

my $client = AnyEvent::Ident::Client->new( hostname => '127.0.0.1', port => $server->bindport );

do {
  my $done = AnyEvent->condvar;
  
  my $res;
  
  $client->ident(400, 500, sub {
    $res = shift;
    $done->send;
  });
  
  $done->recv;
  
  isa_ok $res, 'AnyEvent::Ident::Response';
  ok $res->is_success, 'is_success';
  is $res->username, 'grimlock', 'username = grimlock';
  is $res->os, 'UNIX', 'os = UNIX';
};

do {
  my $done = AnyEvent->condvar;
  
  my $res;
  
  $client->ident(1, 1, sub {
    $res = shift;
    $done->send;
  });
  
  $done->recv;
  
  isa_ok $res, 'AnyEvent::Ident::Response';
  ok !$res->is_success, '!is_success';
  is $res->error_type, 'NO-USER', 'error_type = NO-USER';
};

do {
  my $done = AnyEvent->condvar;
  
  my $res;
  
  $client->ident(-1, -1, sub {
    $res = shift;
    $done->send;
  });
  
  $done->recv;
  
  isa_ok $res, 'AnyEvent::Ident::Response';
  ok !$res->is_success, '!is_success';
  is $res->error_type, 'INVALID-PORT', 'error_type = INVALID-PORT';
};

do {
  my $done = AnyEvent->condvar;
  
  my $res;
  
  $client->ident(65536, 42, sub {
    $res = shift;
    $done->send;
  });
  
  $done->recv;
  
  isa_ok $res, 'AnyEvent::Ident::Response';
  ok !$res->is_success, '!is_success';
  is $res->error_type, 'INVALID-PORT', 'error_type = INVALID-PORT';
};

do {
  my $done = AnyEvent->condvar;
  
  my $res;
  
  $client->ident(42, 65536, sub {
    $res = shift;
    $done->send;
  });
  
  $done->recv;
  
  isa_ok $res, 'AnyEvent::Ident::Response';
  ok !$res->is_success, '!is_success';
  is $res->error_type, 'INVALID-PORT', 'error_type = INVALID-PORT';
};

eval { 
  $server->stop;
  $bind = AnyEvent->condvar;
  $server->start(sub {
    my $tx = shift;
    if($tx->req->server_port == 999
    && $tx->req->client_port == 888)
    {
      $tx->reply_with_user('UNIX', 'grimlock');
    }
    else
    {
      $tx->reply_with_error('NO-USER');
    }
  });
  $bind->recv;
};
diag $@ if $@;

$client = AnyEvent::Ident::Client->new( hostname => '127.0.0.1', port => $server->bindport );

do {
  my $done = AnyEvent->condvar;
  
  my $res;
  
  $client->ident(999, 888, sub {
    $res = shift;
    $done->send;
  });
  
  $done->recv;
  
  isa_ok $res, 'AnyEvent::Ident::Response';
  ok $res->is_success, 'is_success';
  is $res->username, 'grimlock', 'username = grimlock';
  is $res->os, 'UNIX', 'os = UNIX';
};

do {
  my $done = AnyEvent->condvar;
  
  my $res;
  
  $client->ident(400, 500, sub {
    $res = shift;
    $done->send;
  });
  
  $done->recv;
  
  isa_ok $res, 'AnyEvent::Ident::Response';
  ok !$res->is_success, '!is_success';
  is $res->error_type, 'NO-USER', 'error_type = NO-USER';
};
