use strict;
use warnings;
use Test::More tests => 11;
use AnyEvent;
use AnyEvent::Ident qw( ident_server ident_client );

our $timeout = AnyEvent->timer( 
  after => 10,
  cb    => sub { diag "TIMEOUT"; exit },
);

my $bindport = eval {
  my $bind = AnyEvent->condvar;
  ident_server '127.0.0.1', 0, sub {
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
  }, { on_bind => sub { $bind->send(shift) } };
  $bind->recv->bindport;
};

like $bindport, qr/^[123456789]\d*$/, "bind port = " . $bindport;

my $w = AnyEvent->timer( after => 5, cb => sub { diag "TIMEOUT"; exit } );

do {
  my $done = AnyEvent->condvar;
  
  my $res;
  
  ident_client '127.0.0.1', $bindport, 400, 500, sub {
    $res = shift;
    $done->send;
  };
  
  $done->recv;
  
  isa_ok $res, 'AnyEvent::Ident::Response';
  ok $res->is_success, 'is_success';
  is $res->username, 'grimlock', 'username = grimlock';
  is $res->os, 'UNIX', 'os = UNIX';
};

do {
  my $done = AnyEvent->condvar;
  
  my $res;
  
  ident_client '127.0.0.1', $bindport, 1,1, sub {
    $res = shift;
    $done->send;
  };
  
  $done->recv;
  
  isa_ok $res, 'AnyEvent::Ident::Response';
  ok !$res->is_success, '!is_success';
  is $res->error_type, 'NO-USER', 'error_type = NO-USER';
};

do {
  my $done = AnyEvent->condvar;
  
  my $res;
  
  ident_client '127.0.0.1', $bindport, -1, -1, sub {
    $res = shift;
    $done->send;
  };
  
  $done->recv;
  
  isa_ok $res, 'AnyEvent::Ident::Response';
  ok !$res->is_success, '!is_success';
  is $res->error_type, 'INVALID-PORT', 'error_type = INVALID-PORT';
};
