#!/usr/bin/perl
#
# Copyright (C) 2011 by Mark Hindess

use strict;
use constant {
  DEBUG => $ENV{ANYEVENT_MOCK_TCP_SERVER_TEST_DEBUG}
};
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
                                   [ recv => 'HELLO',
                                     'wait for "HELLO"' ],
                                   [ sleep => 0.1, 'wait 0.1s' ],
                                   [ code => sub { ok(1, 'ran code') },
                                     'run code' ],
                                   [ send => 'BYE', 'send "BYE"' ],
                                  ]
                                 ]);
};
plan skip_all => "Failed to create dummy server: $@" if ($@);
my ($host, $port) = $server->connect_address;
plan tests => 9;

is($server->connect_host, $host, 'same host');
is($server->connect_port, $port, 'same port');
is($server->connect_string, $host.':'.$port, 'same host:port');
my $timeout = AnyEvent->timer(after => 20,
                              cb => sub { $done->send('timeout') });

tcp_connect $host, $port, sub {
  my ($fh) = @_;
  ok($fh, 'connected') or die "Failed to connect: $!\n";
  my $hdl;
  $hdl = AnyEvent::Handle->new(
                               fh => $fh,
                               on_error => sub { $done->send('error') });
  $hdl->push_write('HELLO');
  $hdl->on_drain(sub {
                   ok(1, 'drained');
                   $hdl->push_read(chunk => 3, sub {
                                     my ($handle, $data) = @_;
                                     is($data, 'BYE', '... got bye');
                                     $done->send('done');
                                   });
                 });
};

my $res = $done->recv;
is($res, 'done', 'done');
