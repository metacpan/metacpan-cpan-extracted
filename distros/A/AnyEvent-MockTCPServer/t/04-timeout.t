#!/usr/bin/perl
#
# Copyright (C) 2011 by Mark Hindess

use strict;
use constant {
  DEBUG => $ENV{ANYEVENT_MOCK_TCP_SERVER_TEST_DEBUG}
};
BEGIN {
  $ENV{PERL_ANYEVENT_MODEL} = 'Perl';
}
use Test::More;
use AnyEvent::Socket;
use AnyEvent::MockTCPServer qw/:all/;

my $done = AnyEvent->condvar;
my $server;
eval {
  $server =
    AnyEvent::MockTCPServer->new(connections =>
                                 [
                                  [
                                   [ packrecv => '48454C4C4F',
                                     'wait for "HELLO"' ],
                                   [ packsend => '425945', 'send "BYE"' ],
                                  ]
                                 ],
                                 timeout => 0.1);
};
plan skip_all => "Failed to create dummy server: $@" if ($@);
my ($host, $port) = $server->connect_address;
plan tests => 3;

my $timeout =
  AnyEvent->timer(after => 20, cb => sub { $done->send('timeout') });

my $cv = AnyEvent->condvar;
my $filehandle;
tcp_connect $host, $port, sub {
  my ($fh) = @_;
  ok($fh, 'connected') or die "Failed to connect: $!\n";
  $filehandle = $fh;
  $cv->send(1);
};

$cv->recv; # connected

my $res = 'none';
eval { $res = $done->recv; };
is($@, "server timeout\n", 'server timeout');
is($res, 'none', 'not done');
