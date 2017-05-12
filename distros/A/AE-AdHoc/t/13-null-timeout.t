#!/usr/bin/perl -w

use strict;
use Test::More;
use Test::Exception;

use AE::AdHoc;

my @warn;
$SIG{__WARN__} = sub { push @warn, shift };

plan tests => 4;

throws_ok {
	ae_recv{ };
} qr(timeout.*non-?zero), "No timeout = no go";

throws_ok {
	ae_recv{ } "foo";
} qr(timeout.*non-?zero), "Non-numeric timeout = no go";

throws_ok {
	ae_recv{ } 0.01;
} qr(^Timeout after), "Timeout with empty body";

is (scalar @warn, 0, "no warnings");
note "warning: $_" for @warn;
