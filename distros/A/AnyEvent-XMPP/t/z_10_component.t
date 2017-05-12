#!perl

use strict;
use Test::More;
use AnyEvent;
use AnyEvent::XMPP::Component;

my ($host, $dom, $port, $pass) = split /:/, $ENV{NET_XMPP2_TEST_COMPONENT};
if ($host eq '') {
   plan skip_all => 'NET_XMPP2_TEST_COMPONENT environment variable not set';
   exit;
}

plan tests => 1;

my $cv = AnyEvent->condvar;
my $com =
   AnyEvent::XMPP::Component->new (
      domain => $dom,
      host   => $host,
      port   => $port,
      secret => $pass,
   );

my $connected = 0;
$com->reg_cb (
   session_ready => sub {
      my ($com) = @_;
      $connected = 1;
      $cv->send;
   },
   disconnect => sub {
      my ($com) = @_;
      $connected = -1;
      $cv->send;
   }
);

$com->connect;

$cv->recv;

is ($connected, 1, 'component connected successfully');
