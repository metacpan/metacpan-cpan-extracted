#!perl

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use DateTimeX::Easy;
my $dt;


{
    $dt = DateTimeX::Easy->new("2008-09-16 13:23:57 Eastern Daylight");
    is($dt->time_zone->name, "America/New_York");

    $dt = DateTimeX::Easy->new("2008-09-16 13:23:57 Eastern Daylight Time");
    is($dt->time_zone->name, "America/New_York");

    $dt = DateTimeX::Easy->new("2008-09-16 13:23:57 Eastern Daylight Time (GMT-05:00)");
    is($dt->time_zone->name, "America/New_York");

    $dt = DateTimeX::Easy->new("2008-09-16 13:23:57 (GMT-05:00)");
    is($dt->time_zone->name, "-0500");

    $dt = DateTimeX::Easy->new("2008-09-16 13:23:57 -05:00");
    is($dt->time_zone->name, "-0500");

    $dt = DateTimeX::Easy->new("2008-09-16 13:23:57 -0500");
    is($dt->time_zone->name, "-0500");
}

{
    $dt = DateTimeX::Easy->new("2008-09-16 13:23:57 Pacific Daylight");
    is($dt->time_zone->name, "America/Los_Angeles");

    $dt = DateTimeX::Easy->new("2008-09-16 13:23:57 Pacific Daylight Time");
    is($dt->time_zone->name, "America/Los_Angeles");

    $dt = DateTimeX::Easy->new("2008-09-16 13:23:57 Pacific Daylight Time (GMT-08:00)");
    is($dt->time_zone->name, "America/Los_Angeles");

    $dt = DateTimeX::Easy->new("2008-09-16 13:23:57 (GMT-08:00)");
    is($dt->time_zone->name, "-0800");

    $dt = DateTimeX::Easy->new("2008-09-16 13:23:57 -08:00");
    is($dt->time_zone->name, "-0800");

    $dt = DateTimeX::Easy->new("2008-09-16 13:23:57 -0800");
    is($dt->time_zone->name, "-0800");
}

__END__
"2008-09-16 13:23:57 Eastern Daylight Time (GMT-05:00)"
perl -MDateTimeX::Easy -e 'print DateTimeX::Easy->new("2008-09-16
13:23:57 Eastern Daylight Time (GMT-05:00)");'

which actually works as:
"2008-09-16 13:23:57 (GMT-05:00)"
perl -MDateTimeX::Easy -e 'print DateTimeX::Easy->new("2008-09-16
13:23:57 (GMT-05:00)");'


