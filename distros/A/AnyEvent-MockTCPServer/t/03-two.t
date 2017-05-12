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
my $done2 = AnyEvent->condvar;
my $server;
eval {
  $server =
    AnyEvent::MockTCPServer->new(connections =>
                                 [
                                  [
                                   [ packrecv => '48454C4C4F',
                                     'wait for "HELLO"' ],
                                   [ packsend => '425945', 'send "BYE"' ],
                                  ],
                                  [
                                   [ packrecv => '48454C4C4F32',
                                     'wait for "HELLO2"' ],
                                   [ packsend => '42594532', 'send "BYE2"' ],
                                  ]
                                 ]);
};
plan skip_all => "Failed to create dummy server: $@" if ($@);
my ($host, $port) = $server->connect_address;
plan tests => 10;

my $timeout = AnyEvent->timer(after => 20,
                              cb => sub { $done->send('timeout') });

my $cv = AnyEvent->condvar;
tcp_connect $host, $port, sub {
  my ($fh) = @_;
  ok($fh, 'connected(1)') or die "Failed to connect: $!\n";
  $cv->send(1);
  my $hdl;
  $hdl = AnyEvent::Handle->new(
                               fh => $fh,
                               on_error => sub { $done->send('error') });
  $hdl->push_write('HELLO');
  $hdl->on_drain(sub {
                   ok(1, 'drained(1)');
                   $hdl->push_read(chunk => 3, sub {
                                     my ($handle, $data) = @_;
                                     is($data, 'BYE', '... got bye(1)');
                                     $done->send('done');
                                   });
                 });
};

$cv->recv; # make sure first connect happens first

tcp_connect $host, $port, sub {
  my ($fh) = @_;
  ok($fh, 'connected(2)') or die "Failed to connect: $!\n";
  my $hdl;
  $hdl = AnyEvent::Handle->new(
                               fh => $fh,
                               on_error => sub { $done2->send('error') });
  $hdl->push_write('HELLO2');
  $hdl->on_drain(sub {
                   ok(1, 'drained(2)');
                   $hdl->push_read(chunk => 4, sub {
                                     my ($handle, $data) = @_;
                                     is($data, 'BYE2', '... got bye(2)');
                                     $done2->send('done');
                                   });
                 });
};

is($done->recv, 'done', 'done(1)');
is($done2->recv, 'done', 'done(2)');
