#!/usr/bin/perl

use strict;
use warnings;
use AnyEvent::Impl::Perl;
use AnyEvent;
use AnyEvent::Socket;

use lib::abs '../lib';

use AnyEvent::Socket qw(tcp_connect);
use AnyEvent::SMTP::Server;
use Test::More;

my $MAX_SECONDS = 5;

my $cv = AE::cv;

my $server = AnyEvent::SMTP::Server->new(port => 2525, debug => 0);

# Just have the first connection trigger a shutdown
$server->reg_cb(client => sub {
	diag "srv: client connected: @_";
});

$server->start;

# Connect to trigger the shutdown (and the Condition Variable, below)
tcp_connect('127.0.0.1', 2525, sub {
	diag "diag: client connected";
	$cv->send;
});

$cv->recv();

# XXX Do everything we can think of to stop the server!!!
$server->stop();
undef $server;

# Show that the server continues to listen indefinitely
my $seconds_left = $MAX_SECONDS;

my $new_server = AnyEvent::SMTP::Server->new(port => 2525);

while (--$seconds_left)
{
	eval
	{
		$new_server->start();
		$new_server->stop();
		1;
	} and last;
	#warn `netstat -an | grep :2525 | grep -i listen`;
	warn $@;
	sleep(1);
}

ok($seconds_left, "stopped listening in under $MAX_SECONDS seconds after stop/undef");

done_testing();
