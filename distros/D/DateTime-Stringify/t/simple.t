#!/usr/bin/perl -w
use strict;
use lib 'lib';
use Test::More tests => 3;
use_ok("DateTime");

my $dt = DateTime->new(year   => 1964,
                       month  => 10,
                       day    => 16,
                       hour   => 16,
                       minute => 12,
                       second => 47,
                       nanosecond => 500000000,
                     );

is($dt->datetime, "1964-10-16T16:12:47");
is("$dt", "1964-10-16T16:12:47");
