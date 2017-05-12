#!/usr/bin/env perl

use strict;
use lib::abs '../lib';
use AnyEvent;
use AnyEvent::Memcached;

my $cv = AnyEvent->condvar;
$cv->begin(sub { $cv->send });

my $memd = AnyEvent::Memcached->new(
	servers   => [ '127.0.0.1:11211' ],
	cv        => $cv,
	# debug     => 1,
	namespace => "test:",
);

$memd->set("key1", "val1", cb => sub {
	shift or warn "Set key1 failed: @_";
	warn "Set ok";
	$memd->get("key1", cb => sub {
		my ($v,$e) = @_;
		$e and return warn "Get failed: $e";
		warn "Got value for key1: $v";
	});
});

$cv->end;
$cv->recv;
