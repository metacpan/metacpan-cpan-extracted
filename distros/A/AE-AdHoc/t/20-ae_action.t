#!/usr/bin/perl -w

use strict;
use Test::More tests => 5;
use Test::Exception;

use AE::AdHoc;

my @res;
ae_recv {
	ae_action { push @res, @_ } after=>0.03, interval =>0.1;
} soft_timeout=>0.2;

is_deeply (\@res, [ 0, 1 ], "Timer fired twice");

my $x;
ae_recv {
	ae_action { $x++ };
	ok (!$x, "Action didn't work yet");
} soft_timeout=>0.2;

is ($x, 1, "Action w/o parameters works (finally)");
is_deeply (\@res, [ 0, 1 ], "Timer *still* fired twice");

is_deeply (\@AE::AdHoc::errors, [], "No errors in this test");
