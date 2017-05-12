#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::Most;
use Date::Holidays::SK qw(is_sk_holiday sk_holidays);

plan tests => 10;

ok(is_sk_holiday(2014, 12, 24), "Christmas Eve 2014");

ok(is_sk_holiday(2014, 4, 18), "Easter Friday 2014");
ok(is_sk_holiday(2014, 4, 21), "Easter Monday 2014");

ok( ! is_sk_holiday(2014, 5, 3), "May 3, 2014");

my ($h, $q, @k);

$h = sk_holidays(2014);
$q = scalar keys %$h;
cmp_ok($q, '==', 15, "Right number of elements in 2014 holidays hash");

$h = sk_holidays(2014, 4);
$q = scalar keys %$h;
cmp_ok($q, '==', 2, "Right number of elements in 2014-APR holidays hash");

$h = sk_holidays(2014, 4, 18);
$q = scalar keys %$h;
cmp_ok($q, '==', 1, "Right number of elements in 2014-APR-18 holidays hash");

$h = sk_holidays(2014, 4, 2);
$q = scalar keys %$h;
cmp_ok($q, '==', 0, "Right number of elements in 2014-APR-2 holidays hash");

$h = sk_holidays(2014, 05);
@k = sort keys %$h;
eq_or_diff(\@k, [qw(0501 0508)], "dates in 2014-MAY");

$h = sk_holidays(2014, 11);
@k = sort keys %$h;
eq_or_diff(\@k, [qw(1101 1117)], "dates in 2014-NOV");
