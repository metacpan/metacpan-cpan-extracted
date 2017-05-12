#!perl

use 5.010001;
use strict;
use warnings;

use DateTime::Duration;
use DateTime::Format::Duration::ISO8601;
use Test::More 0.98;

my $d = DateTime::Format::Duration::ISO8601->new;

is($d->format_duration(DateTime::Duration->new()), "PT0H0M0S");
is($d->format_duration(DateTime::Duration->new(years=>1)), "P1Y");
is($d->format_duration(DateTime::Duration->new(hours=>2)), "PT2H");
is($d->format_duration(DateTime::Duration->new(years=>1, months=>2, weeks=>2, days=>7+4, hours=>5, minutes=>6, seconds=>7, nanoseconds=>800_000_000)), "P1Y2M3W4DT5H6M7.8S");

done_testing;
