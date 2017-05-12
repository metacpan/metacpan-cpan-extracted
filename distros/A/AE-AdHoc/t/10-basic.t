#!/usr/bin/perl -w

use strict;
use Test::More tests => 9;
use Test::Exception;

use AE::AdHoc;

throws_ok {
	ae_recv { ; } 0.01;
} qr(Timeout), "empty body => reach timeout => die";

lives_and {
	is ((ae_recv { ae_send->(137); } 0.01), 137 );
} "plain ae_send is fine";

throws_ok {
	ae_send;
} qr(outside), "outside = no go";

throws_ok {
	ae_begin;
} qr(outside), "outside = no go";

my $timer;
throws_ok {
	ae_recv {
		$timer = AnyEvent->timer( after => 0.1, cb => ae_send );
		note "timer ref = $timer";
	} 0.01;
} qr(Timeout), "Start rotten timer test";

# check that later-on callback generates a warning
{
	my @warn;
	local $SIG{__WARN__} = sub { push @warn, @_ };
	throws_ok {
		ae_recv { ; } 0.2;
	} qr(Timeout), "Rotten timer didn't spoil later tests:";
	is (scalar @warn, 1, " - 1 warning issued");
	like ($warn[0], qr(Leftover), " - It was about 'Leftover': $warn[0]");
	ok (ref $timer, " - Rotten timer still alive at this point (but harmless): $timer");

};
