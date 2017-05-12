#!/usr/bin/perl
#
# Copyright (C) 2011 by Mark Hindess

use strict;
use constant {
  DEBUG => $ENV{ANYEVENT_MOCK_TCP_SERVER_TEST_DEBUG}
};
BEGIN {
  $ENV{PERL_ANYEVENT_MODEL} = 'Perl' unless ($ENV{PERL_ANYEVENT_MODEL});
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
                                   [ sleep => 1, 'wait' ],
                                  ]
                                 ],
                                 on_error => sub { $done->send('error'); },
                                );
};
plan skip_all => "Failed to create dummy server: $@" if ($@);
my ($host, $port) = $server->connect_address;
plan tests => 3;

my $timeout =
  AnyEvent->timer(after => 20, cb => sub { $done->send('timeout') });

my $cv = AnyEvent->condvar;
tcp_connect $host, $port, sub {
  my ($fh) = @_;
  ok($fh, 'connected') or die "Failed to connect: $!\n";
  close $fh;
  $cv->send(1);
};

$cv->recv; # connected

my $res = 'none';
my $warn = '';
$SIG{__WARN__} = sub { $warn .= "@_"; };
eval { $res = $done->recv; };
delete $SIG{__WARN__};
like($warn, qr/^error /, 'warn on error');
is($res, 'error', 'error');
