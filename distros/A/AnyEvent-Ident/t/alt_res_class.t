use strict;
use warnings;
use Test::More tests => 7;
use AnyEvent::Ident::Client;
use AnyEvent::Ident::Server;

our $timeout = AnyEvent->timer( 
  after => 10,
  cb    => sub { diag "TIMEOUT"; exit },
);

my $bindport = AnyEvent->condvar;

my $server = eval { AnyEvent::Ident::Server->new(
  hostname => '127.0.0.1', port => 0, on_bind => sub { $bindport->send(shift->bindport) },
) };
diag $@ if $@;
isa_ok $server, 'AnyEvent::Ident::Server';

eval {
  $server->start(sub {
    shift->reply_with_user('UNIX','grimlock');
  });
};
diag $@ if $@;

like $bindport->recv, qr/^[1-9]\d*$/, 'bind port = ' . $server->bindport;

my $w = AnyEvent->timer( after => 5, cb => sub { diag 'TIMEOUT'; exit });

my $done = AnyEvent->condvar;

my $client = AnyEvent::Ident::Client->new(
  hostname => '127.0.0.1',
  port => $server->bindport,
  response_class => 'Foo::Bar::Baz',
)->ident(1,2, sub {
  my $res = shift;

  isa_ok $res, 'Foo::Bar::Baz';  
  ok $res->is_success, 'is_success';
  is $res->username,   'grimlock', ' username = grimlock ';
  is $res->os,         'UNIX',     ' os       = UNIX ';
  is eval { $res->answer }, 42,    ' answer   = 42 ';
  diag $@ if $@;
  
  $done->send;
});

$done->recv;

package
  Foo::Bar::Baz;

BEGIN { our @ISA = qw( AnyEvent::Ident::Response ) }

sub answer { 42 }
