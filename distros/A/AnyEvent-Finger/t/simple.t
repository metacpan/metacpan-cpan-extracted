use strict;
use warnings;
use Test::More tests => 3;
use AnyEvent;
use AnyEvent::Finger qw( finger_server finger_client );

our $timeout = AnyEvent->timer( 
  after => 15, 
  cb    => sub { diag "TIMEOUT"; exit },
);

my $port = eval { 
  my $bind = AnyEvent->condvar;
  my $server = finger_server sub {
    my $tx = shift;
    my $req = $tx->req;
    $tx->res->([
      "request = '$req'",
      undef,
    ]);
  }, { port => 0, hostname => '127.0.0.1', on_bind => sub { $bind->send } };
  $bind->recv;
  $server->bindport;
};
diag $@ if $@;

like $port, qr{^[123456789]\d*$}, "bindport = $port";

my $error = sub { diag shift; exit 2 };

subtest t1 => sub {
  my $done = AnyEvent->condvar;

  my $lines;
  finger_client '127.0.0.1', '', sub {
    ($lines) = shift;
    $done->send;
  }, { port => $port, on_error => $error};
  
  $done->recv;
  
  is $lines->[0], "request = ''", 'response is correct';
};

subtest t2 => sub {
  my $done = AnyEvent->condvar;

  my $lines;
  finger_client '127.0.0.1', 'grimlock', sub {
    ($lines) = shift;
    $done->send;
  }, { port => $port, on_error => $error };
  
  $done->recv;
  
  is $lines->[0], "request = 'grimlock'", 'response is correct';
};
