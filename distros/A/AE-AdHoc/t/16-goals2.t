#!/usr/bin/perl -w

use strict;
use Test::More tests => 8;
use Test::Exception;

use AE::AdHoc;

throws_ok {
	ae_recv {
		ae_goal("never");
		ae_goal("always")->();
	} 0.1;
} qr(^Timeout), "Goals not done, sorry";
is_deeply( AE::AdHoc->results, { always => [] }, "1 goal done");
is_deeply( AE::AdHoc->goals, { never => 1 }, "1 goal left");

ae_recv { ae_send->(137) } 0.1;

is_deeply( AE::AdHoc->results, { }, "results cleared");
is_deeply( AE::AdHoc->goals, { }, "goals cleared");

throws_ok {
	ae_recv {
		ae_goal("never") for 1..3;
		ae_goal("always")->($_) for 1..3;
	} 0.1;
} qr(^Timeout), "Goals not done, sorry";
is_deeply( AE::AdHoc->results, { always => [1] }, "only first goal callback counts");
is_deeply( AE::AdHoc->goals, { never => 3 }, "1 goal left, but 3 times");

