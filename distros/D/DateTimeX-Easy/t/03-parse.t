#!perl

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use DateTimeX::Easy;

my $yyy = (localtime(time))[5] + 1900;

for (split m/\n/, <<_END_) {
1994-06-16T07:29:35 @ -0600 | Wed, 16 Jun 94 07:29:35 CST
1994-10-13T10:13:13 @ -0700 | Thu, 13 Oct 94 10:13:13 -0700
1994-11-09T09:50:32 @ -0500 | Wed, 9 Nov 1994 09:50:32 -0500 (EST)
$yyy-12-21T17:05:00 | 21 dec 17:05
$yyy-12-21T17:05:00 | 21-dec 17:05
$yyy-12-21T17:05:00 | 21/dec 17:05
1993-12-21T17:05:00 | 21/dec/93 17:05
1999-01-01T10:02:18 @ UTC | 1999 10:02:18 "GMT"
1994-11-16T22:28:20 @ -0800 | 16 Nov 94 22:28:20 PST
_END_
    next if m/^\s*#/;
    my ($want, $from) = split m/\s*\|\s*/, $_, 2;
    my ($want_dt, $want_tz) = split m/\s*\@\s*/, $want, 2;
    $want_tz ||= "floating";

    my $dt = DateTimeX::Easy->new($from);
    is($dt, $want_dt);
    is($dt->time_zone->name, $want_tz);
}
