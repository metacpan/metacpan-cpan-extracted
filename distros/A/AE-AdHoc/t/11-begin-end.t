#!/usr/bin/perl -w

use strict;
use Test::More;
use Test::Exception;

use AE::AdHoc;

my @timers;

plan tests => 5;

lives_ok {
	my $timer;
	ae_recv {
		ae_begin;
		$timer = AnyEvent->timer( after => 0.01, cb => ae_end );
	} 1;
} "A simple begin/end example works";

throws_ok {
	my $timer;
	ae_recv {
		ae_begin;
		ae_begin;
		$timer = AnyEvent->timer( after => 0.01, cb => ae_end );
	} 0.02;
} qr(Timeout), "A simple example with extra begin dies";

my @trace;
my $val;

lives_ok {
	ae_recv {
		my $tm;
		my $iter;
		my $attimer;
		$attimer = sub {
			push @trace, ++$iter;
			ae_end->();
			$tm = AE::timer 0.01, 0, $attimer;
		};
		$tm = AE::timer 0.01, 0, $attimer;
		ae_begin( sub { ae_send->(++$val) } ) for (1,2);
	} 1;
} "More complex example lives";

is ($val, 1, "Begin's callback executed once");
is_deeply(\@trace, [1, 2], "end->() executed twice");

