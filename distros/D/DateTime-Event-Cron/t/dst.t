#!/usr/bin/perl -w
use strict;
use lib './lib';
use Test::More tests => 12;

use DateTime;
use DateTime::Event::Cron;

sub make_datetime {
  @_ == 6 or die "Invalid argument count\n";
  DateTime->new(
    year => $_[0], month  => $_[1], day    => $_[2],
    hour => $_[3], minute => $_[4], second => $_[5],
    time_zone => "America/New_York",
  );
}

sub dcomp { is(shift->datetime, shift->datetime, shift) }

my($desc, $dtc, $old, $new, $date);

$desc = "DST minute increment";
$dtc = DateTime::Event::Cron->new_from_cron("*/5 * * * *");
ok($dtc, "$desc create");
$old = make_datetime(2017, 3, 12, 1, 55, 0);
$new = $dtc->next($old);
$date = make_datetime(2017, 3, 12, 3, 0, 0);
dcomp($new, $date, "$desc next");

$desc = "DST minute decrement";
$dtc = DateTime::Event::Cron->new_from_cron("*/5 * * * *");
ok($dtc, "$desc create");
$old = make_datetime(2017, 3, 12, 3, 0, 0);
$new = $dtc->previous($old);
$date = make_datetime(2017, 3, 12, 1, 55, 0);
dcomp($new, $date, "$desc next");

$desc = "DST hour increment";
$dtc = DateTime::Event::Cron->new_from_cron("30 * * * *");
ok($dtc, "$desc create");
$old = make_datetime(2017, 3, 12, 1, 30, 0);
$new = $dtc->next($old);
$date = make_datetime(2017, 3, 12, 3, 30, 0);
dcomp($new, $date, "$desc next");

$desc = "DST hour decrement";
$dtc = DateTime::Event::Cron->new_from_cron("30 * * * *");
ok($dtc, "$desc create");
$old = make_datetime(2017, 3, 12, 3, 30, 0);
$new = $dtc->previous($old);
$date = make_datetime(2017, 3, 12, 1, 30, 0);
dcomp($new, $date, "$desc next");

$desc = "DST day increment";
$dtc = DateTime::Event::Cron->new_from_cron("30 2 * * *");
ok($dtc, "$desc create");
$old = make_datetime(2017, 3, 11, 2, 30, 0);
$new = $dtc->next($old);
$date = make_datetime(2017, 3, 13, 2, 30, 0);
dcomp($new, $date, "$desc next");

$desc = "DST day decrement";
$dtc = DateTime::Event::Cron->new_from_cron("*/5 * * * *");
ok($dtc, "$desc create");
$old = make_datetime(2017, 3, 12, 3, 0, 0);
$new = $dtc->previous($old);
$date = make_datetime(2017, 3, 12, 1, 55, 0);
dcomp($new, $date, "$desc next");

# End test
