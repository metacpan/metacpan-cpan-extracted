#!/usr/bin/perl -w

use strict;
use Test::More tests => 5;
use Test::Exception;

use AE::AdHoc;

my @list;
my $scalar;

@list = ae_recv {
	ae_send(1..5)->(6..10);
} 0.01;

is_deeply (\@list, [1..10], "Extra args in list context");

$scalar = ae_recv {
	ae_send(1..5)->(6..10);
} 0.01;

is ($scalar, 1, "Extra args in scalar context");

$scalar = ae_recv {
	ae_send->(6..10);
} 0.01;

is ($scalar, 6, "Multiple args in scalar context");

# Error handling

throws_ok {
	ae_recv {
		ae_croak("bump bump")->("real error");
	} 0.01;
} qr(^bump bump), "Extra args in croak";

unlike ($@, qr(real error), "Sorry, no real error for you");
