#!/usr/bin/perl -w

use strict;
use Test::More tests => 2;
use Test::Exception;

use AE::AdHoc;

lives_ok {
	ae_recv { } soft_timeout => 0.1
} "soft timeout";

throws_ok {
	ae_recv { } timeout => 0.1
} qr(Timeout.*seconds), "hard timeout in options";
