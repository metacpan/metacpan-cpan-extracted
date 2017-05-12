# Copyright (c) 2007 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# test DateTime interface

use strict;

eval "use DateTime 0.1501";
if ($@) {
   print "1..0 # SKIP DateTime 0.1501 or later required for these tests\n";
   exit 0;
}

use Date::Gregorian;
use Date::Gregorian::Business;

$| = 1;

print "1..69\n";

sub skip {
    my ($from, $to, $reason) = @_;
    print map "ok $_ # SKIP $reason\n", $from..$to;
}

sub test {
    my ($n, $ok) = @_;
    print !$ok && 'not ', "ok $n\n";
}

my $tz = 'Europe/Berlin';
my $dt = eval {
    DateTime->new(
	year       => 1997,
	month      => 6,
	day        => 14,
	hour       => 18,
	minute     => 30,
	second     => 22,
	nanosecond => 250000000,
	time_zone  => $tz,
    );
};
if ($@) {
    skip 1, 16, "timezone not working: $tz";
}
else {
    test 1, 1;
    test 2, $dt;
    test 3, $dt->isa('DateTime');
    my $tz = $dt->time_zone;
    test 4, !$tz->is_floating;

    my $date = Date::Gregorian->new->set_datetime($dt);
    test 5, $date;
    test 6, $date->isa('Date::Gregorian');
    test 7, $dt->time_zone == $tz;

    my $date2 = $date->new->add_days(153+365);
    test 8, $date2;

    my $dt2 = DateTime->from_object(object => $date2);
    test 9, $dt2;
    test 10, $dt2->isa('DateTime');
    test 11, $dt2->time_zone->is_floating;

    my $delta = $dt2 - $dt;
    test 12, $delta;
    test 13, $delta->isa('DateTime::Duration');

    my ($dm, $dd, $dM, $dS, $dn) =
	$delta->in_units(
	    'months', 'days', 'minutes', 'seconds', 'nanoseconds'
	);
    test 14, 17 == $dm;
    test 15, 0 == $dd;
    test 16, 0 == $dM && 0 == $dS && 0 == $dn;
}

$dt = DateTime->new(
    year       => 1997,
    month      => 6,
    day        => 14,
    hour       => 18,
    minute     => 30,
    second     => 22,
    nanosecond => 250000000,
);
my $date = Date::Gregorian->new->set_ymd(1997, 6, 14);
test 17, $date;
my $dt2 = DateTime->from_object(object => $date);
test 18, $dt2;
test 19, $dt2->isa('DateTime');
test 20, $dt2->time_zone->is_floating;

my $dt1 = $dt->clone->truncate(to => 'day');

my $delta = $dt2 - $dt1;
test 21, $delta;
test 22, $delta->isa('DateTime::Duration');

my ($dm, $dd, $dM, $dS, $dn) =
    $delta->in_units(
	'months', 'days', 'minutes', 'seconds', 'nanoseconds'
    );
test 23, 0 == $dm;
test 24, 0 == $dd;
test 25, 0 == $dM && 0 == $dS && 0 == $dn;

my $date2 = Date::Gregorian->from_object('object' => $dt);
test 26, $date2;
test 27, $date2->isa('Date::Gregorian');
test 28, 0 == $date2->compare($date);

my $date3 = Date::Gregorian->from_object('object' => $dt1);
test 29, $date3;
test 30, $date3->isa('Date::Gregorian');
test 31, 0 == $date3->compare($date);

my $dt3 = DateTime->from_object(object => $date2);

$delta = $dt3 - $dt;
test 32, $delta;
test 33, $delta->isa('DateTime::Duration');

($dm, $dd, $dM, $dS, $dn) =
    $delta->in_units(
	'months', 'days', 'minutes', 'seconds', 'nanoseconds'
    );
test 34, 0 == $dm;
test 35, 0 == $dd;
test 36, 0 == $dM && 0 == $dS && 0 == $dn;

$date3 = $date2->new;
test 37, $date3;
test 38, $date3 != $date2;

my $result = $date3->truncate_to_day;
test 39, $result == $date3;
my $dt4 = DateTime->from_object(object => $date3);

$delta = $dt4 - $dt1;
test 40, $delta;
test 41, $delta->isa('DateTime::Duration');

($dm, $dd, $dM, $dS, $dn) =
    $delta->in_units(
	'months', 'days', 'minutes', 'seconds', 'nanoseconds'
    );
test 42, 0 == $dm;
test 43, 0 == $dd;
test 44, 0 == $dM && 0 == $dS && 0 == $dn;

my @rd = $date2->utc_rd_values;
test 45, 3 == @rd;
test 46, (18 * 60 + 30) * 60 + 22 == $rd[1];
test 47, 250000000 == $rd[2];
my $rd0 = $rd[0];

$result = $date2->add_days(-1);
test 48, $result == $date2;
@rd = $date2->utc_rd_values;
test 49, 3 == @rd;
test 50, $rd0 - 1 == $rd[0];
test 51, (18 * 60 + 30) * 60 + 22 == $rd[1];
test 52, 250000000 == $rd[2];

@rd = $date3->utc_rd_values;
test 53, 3 == @rd;
test 54, $rd0 == $rd[0];
test 55, 0 == $rd[1];
test 56, 0 == $rd[2];

@rd = $date->utc_rd_values;
test 57, 3 == @rd;
test 58, $rd0 == $rd[0];
test 59, 0 == $rd[1];
test 60, 0 == $rd[2];

$dt3 = DateTime->new(
    year       => 1997,
    month      => 6,
    day        => 13,
    hour       => 5,
    minute     => 44,
    second     => 1,
    time_zone  => 'UTC',
);
test 61, $dt3;

$date3 = Date::Gregorian->from_object(object => $dt3);
test 62, $date3;
test 63, 0 == $date3->compare($date2);
test 64, 0 == $date3->get_days_since($date2);
test 65, DateTime->compare($dt, $dt3) > 0;

my $date4 = Date::Gregorian::Business->new('us')->set_datetime($dt3);
test 66, $date4;
test 67, !$date4->compare($date2);
test 68, !$date4->compare($date3);
test 69, !$date3->compare($date4);

__END__
