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
  $server = AnyEvent::MockTCPServer->new();
};
plan skip_all => "Failed to create dummy server: $@" if ($@);
my ($host, $port) = $server->connect_address;
plan tests => 2;

my $timeout = AnyEvent->timer(after => 5,
                              cb => sub { $done->send('timeout') });

tcp_connect $host, $port, sub {};

my $res = '';
eval { $res = $done->recv };
is($@, "Server received unexpected connection\n", 'unexpected connection');
is($res, '', 'no timeout');
