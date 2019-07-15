#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use DateTime::Duration;
use DateTime::Format::Duration::ConciseHMS;

subtest "format" => sub {
    my $f = DateTime::Format::Duration::ConciseHMS->new;

    is($f->format_duration(DateTime::Duration->new()),
       "00:00:00", 'empty duration');
    is($f->format_duration(DateTime::Duration->new(years=>1)),
       "1y", 'one year');
    is($f->format_duration(DateTime::Duration->new(hours=>2)),
       "02:00:00", 'two hours');
    is($f->format_duration(DateTime::Duration->new(years=>1, months=>2, weeks=>2, days=>7+4, hours=>5, minutes=>6, seconds=>7, nanoseconds=>800_000_000)),
       "1y 2mo 25d 05:06:07.800", 'all duration fields');
    eval { $f->format_duration("123") };
    ok $@ =~ m[not a DateTime::Duration instance], 'invalid dt arg';
};

done_testing;
