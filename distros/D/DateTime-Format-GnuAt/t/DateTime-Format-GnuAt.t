#!/usr/bin/perl

# Copyright (c) 2013, Qindel Formación y Servicios S.L.
#
# This file was based on parsetime.pl which have the following copyright:
#
# Copyright (C) 2009, Ansgar Burchardt <ansgar@debian.org>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.

use strict;
use warnings;

use Test::More tests => 29;
use DateTime::Format::GnuAt;

my $parser = DateTime::Format::GnuAt->new;

my $now;

my @wdays  = qw(Mon Tue Wed Thu Fri Sat Sun);
my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

sub test {
    my ($timespec, $expected, $test_name) = @_;
    $test_name = "$now: $timespec => $expected" unless defined $test_name;
    my $now_dt = DateTime->from_epoch(epoch => $now);
    $now_dt->set_time_zone($ENV{TZ});

    my $got = eval {
        my $got_dt = $parser->parse_datetime($timespec, now => $now_dt);
        $got_dt->set_time_zone($ENV{TZ});
        sprintf("%s %s %d %s %d",
                $wdays[$got_dt->day_of_week - 1],
                $months[$got_dt->month - 1],
                $got_dt->day,
                $got_dt->hms,
                $got_dt->year);
    } // 'Ooops...';
    is($got, $expected, $test_name);
}

$ENV{TZ} = 'UTC';
$now     = 1258462020; # Tue Nov 17 12:47:00 2009

# now, + relative
test("now", "Tue Nov 17 12:47:00 2009");
test("now + 1 min", "Tue Nov 17 12:48:00 2009");
test("now + 23 min", "Tue Nov 17 13:10:00 2009");
test("now + 1 hour", "Tue Nov 17 13:47:00 2009");
test("now + 23 hours", "Wed Nov 18 11:47:00 2009");
test("now + 1 day", "Wed Nov 18 12:47:00 2009");
test("now + 1 week", "Tue Nov 24 12:47:00 2009");
test("now + 1 month", "Thu Dec 17 12:47:00 2009");
test("now + 1 year", "Wed Nov 17 12:47:00 2010");

# later this day, + relative
test("23:55", "Tue Nov 17 23:55:00 2009");
test("23:55 + 7 min", "Wed Nov 18 00:02:00 2009");

# earlier this day, + relative
test("12:00", "Wed Nov 18 12:00:00 2009");
test("12:00 + 5 min", "Wed Nov 18 12:05:00 2009");
test("12:00 + 2 hours", "Wed Nov 18 14:00:00 2009");

# date in the future
test("12:00 Dec 17", "Thu Dec 17 12:00:00 2009");

# date in the past
test("12:00 Oct 17", "Sun Oct 17 12:00:00 2010");
test("12:00 Oct 17 + 7 days", "Sun Oct 24 12:00:00 2010");
test("12:00 Oct 17 + 35 days", "Sun Nov 21 12:00:00 2010");

# going into the next year
test("00:00 Dec 24", "Thu Dec 24 00:00:00 2009");
test("00:00 Dec 24 + 31 days", "Sun Jan 24 00:00:00 2010");
test("00:00 Dec 24 + 358 days", "Fri Dec 17 00:00:00 2010");

test("23:55 Dec 31", "Thu Dec 31 23:55:00 2009");
test("23:55 Dec 31 + 7 minutes", "Fri Jan 1 00:02:00 2010");

# invalid dates
test("Jan 32", "Ooops...");
test("Feb 30", "Ooops...");
test("Apr 31", "Ooops...");
test("May -1", "Ooops...");
test("Oct 0", "Ooops...");

# http://bugs.debian.org/364975
$ENV{TZ} = "America/New_York";
$now = 1146160800; # Apr 27 2006 18:00 UTC
test("20:00 UTC", "Thu Apr 27 16:00:00 2006");

1;

