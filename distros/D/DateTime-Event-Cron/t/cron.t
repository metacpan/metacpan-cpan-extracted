#!/usr/bin/perl -w
use strict;
use lib './lib';
use Test::More tests => 86;

use DateTime;
use DateTime::Event::Cron;

sub make_datetime {
  @_ == 6 or die "Invalid argument count\n";
  DateTime->new(
    year => $_[0], month  => $_[1], day    => $_[2],
    hour => $_[3], minute => $_[4], second => $_[5],
  );
}

sub dcomp { is(shift->datetime, shift->datetime, shift) }

my($odate, $date, $new, $dts, $dtc, $dtd, $desc);

# Next and previous, delta 60 secs or so. Explicit now()
$dts = DateTime::Event::Cron->from_cron(cron => '* * * * *');
$desc = "delta span, explicit now";
$dtd = DateTime::Duration->new(seconds => 62);
ok($dts, "$desc create");
$date  = DateTime->now;
$new = $dts->next($date);
cmp_ok( ($new - $date)->seconds, '<', $dtd->seconds, "$desc next");
$new = $dts->previous($date);
cmp_ok( ($date - $new)->seconds, '<', $dtd->seconds, "$desc prev");

# Next and previous, delta 60 secs or so. Implicit now() (not
# possible using set methods so we go native)
$desc = "delta span, implicit now";
$dtc = DateTime::Event::Cron->new_from_cron(cron => '* * * * *');
ok($dtc, "$desc create");
$date  = DateTime->now;
$new = $dtc->next();
cmp_ok( ($new - $date)->seconds, '<', $dtd->seconds, "$desc next");
$date  = DateTime->now;
$new = $dtc->previous();
cmp_ok( ($date - $new)->seconds, '<', $dtd->seconds, "$desc prev");

# cron on sunday once a week, 0-based dow
$desc = 'every sunday, 0-based';
$dts = DateTime::Event::Cron->from_cron(cron => '12 21 * * 0');
ok($dts, "$desc create");
$odate = make_datetime(2002,9,9,15,10,0);
$date = $odate->clone;
$new = $dts->next($date);
$date = make_datetime(2002,9,15,21,12,0);
dcomp($new, $date, "$desc next");
$new = $dts->next($date);
$date = make_datetime(2002,9,22,21,12,0);
dcomp($new, $date, "$desc next");
$new = $dts->next($date);
$date = make_datetime(2002,9,29,21,12,0);
dcomp($new, $date, "$desc next");

$date = $odate->clone;
$new = $dts->previous($date);
$date = make_datetime(2002,9,8,21,12,0);
dcomp($new, $date, "$desc prev");
$new = $dts->previous($date);
$date = make_datetime(2002,9,1,21,12,0);
dcomp($new, $date, "$desc prev");
$new = $dts->previous($date);
$date = make_datetime(2002,8,25,21,12,0);
dcomp($new, $date, "$desc prev");

# cron on sunday, once a week 7-based dow
$desc = 'every sunday, 7-based';
$dts = DateTime::Event::Cron->from_cron(cron => '12 21 * * 7');
ok($dts, "$desc create");
$odate = make_datetime(2002,9,9,15,10,0);
$date = $odate->clone;
$new = $dts->next($date);
$date = make_datetime(2002,9,15,21,12,0);
dcomp($new, $date, "$desc next");
$date = $odate->clone;
$new = $dts->previous($date);
$date = make_datetime(2002,9,8,21,12,0);
dcomp($new, $date, "$desc prev");

# cron twice a week on tuesdays and thursdays
$desc = 'every tues/thurs';
$dts = DateTime::Event::Cron->from_cron(cron => '12 21 * * 2,4');
ok($dts, "$desc create");
$odate = make_datetime(2002,9,9,15,10,0);
$date = $odate->clone;
$new = $dts->next($date);
$date = make_datetime(2002,9,10,21,12,0);
dcomp($new, $date, "$desc next");
$new = $dts->next($date);
$date = make_datetime(2002,9,12,21,12,0);
dcomp($new, $date, "$desc next");
$new = $dts->next($date);
$date = make_datetime(2002,9,17,21,12,0);
dcomp($new, $date, "$desc next");

$date = $odate->clone;
$new = $dts->previous($date);
$date = make_datetime(2002,9,5,21,12,0);
dcomp($new, $date, "$desc prev");
$new = $dts->previous($date);
$date = make_datetime(2002,9,3,21,12,0);
dcomp($new, $date, "$desc prev");
$new = $dts->previous($date);
$date = make_datetime(2002,8,29,21,12,0);
dcomp($new, $date, "$desc prev");

# job runs once a week on fridays and every 5 days
$desc = 'every fri & 5 days';
$dts = DateTime::Event::Cron->from_cron(cron => '30 10 */5 * 5');
ok($dts, "$desc create");
$odate = make_datetime(2002,9,9,5,10,0);
$date = $odate->clone;
$new = $dts->next($date);
$date = make_datetime(2002,9,11,10,30,0);
dcomp($new, $date, "$desc next");
$new = $dts->next($date);
$date = make_datetime(2002,9,13,10,30,0);
dcomp($new, $date, "$desc next");
$new = $dts->next($date);
$date = make_datetime(2002,9,16,10,30,0);
dcomp($new, $date, "$desc next");
$new = $dts->next($date);
$date = make_datetime(2002,9,20,10,30,0);
dcomp($new, $date, "$desc next");
$new = $dts->next($date);
$date = make_datetime(2002,9,21,10,30,0);
dcomp($new, $date, "$desc next");

$date = $odate->clone;
$new = $dts->previous($date);
$date = make_datetime(2002,9,6,10,30,0);
dcomp($new, $date, "$desc prev");
$new = $dts->previous($date);
$date = make_datetime(2002,9,1,10,30,0);
dcomp($new, $date, "$desc prev");
$new = $dts->previous($date);
$date = make_datetime(2002,8,31,10,30,0);
dcomp($new, $date, "$desc prev");
$new = $dts->previous($date);
$date = make_datetime(2002,8,30,10,30,0);
dcomp($new, $date, "$desc prev");
$new = $dts->previous($date);
$date = make_datetime(2002,8,26,10,30,0);
dcomp($new, $date, "$desc prev");
$new = $dts->previous($date);
$date = make_datetime(2002,8,23,10,30,0);
dcomp($new, $date, "$desc prev");

# cron every hour
$desc = 'every hour';
$dts = DateTime::Event::Cron->from_cron(cron => '42 * * * *');
ok($dts, "$desc create");
$odate = make_datetime(1987,6,21,9,51,0);
$date = $odate->clone;
$new = $dts->next($date);
$date = make_datetime(1987,6,21,10,42,0);
dcomp($new, $date, "$desc next");
$new = $dts->next($date);
$date = make_datetime(1987,6,21,11,42,0);
dcomp($new, $date, "$desc next");
$new = $dts->next($date);
$date = make_datetime(1987,6,21,12,42,0);
dcomp($new, $date, "$desc next");

$date = $odate->clone;
$new = $dts->previous($date);
$date = make_datetime(1987,6,21,9,42,0);
dcomp($new, $date, "$desc prev");
$new = $dts->previous($date);
$date = make_datetime(1987,6,21,8,42,0);
dcomp($new, $date, "$desc prev");
$new = $dts->previous($date);
$date = make_datetime(1987,6,21,7,42,0);
dcomp($new, $date, "$desc prev");

# cron on assorted hours
$desc = "assorted hours";
$dts = DateTime::Event::Cron->from_cron(cron => '42 13,15,22,23 * * *');
ok($dts, "$desc create");
$odate = make_datetime(1987,6,21,17,51,0);
$date = $odate->clone;
$new = $dts->next($date);
$date = make_datetime(1987,6,21,22,42,0);
dcomp($new, $date, "$desc next");
$new = $dts->next($date);
$date = make_datetime(1987,6,21,23,42,0);
dcomp($new, $date, "$desc next");
$new = $dts->next($date);
$date = make_datetime(1987,6,22,13,42,0);
dcomp($new, $date, "$desc next");

$date = $odate->clone;
$new = $dts->previous($date);
$date = make_datetime(1987,6,21,15,42,0);
dcomp($new, $date, "$desc prev");
$new = $dts->previous($date);
$date = make_datetime(1987,6,21,13,42,0);
dcomp($new, $date, "$desc prev");
$new = $dts->previous($date);
$date = make_datetime(1987,6,20,23,42,0);
dcomp($new, $date, "$desc prev");
$new = $dts->previous($date);
$date = make_datetime(1987,6,20,22,42,0);
dcomp($new, $date, "$desc prev");

# cron every minute of 5pm
$desc = "every minute of 5pm";
$dts = DateTime::Event::Cron->from_cron(cron => '* 17 * * *');
ok($dts, "$desc create");
$odate = make_datetime(1987,6,21,17,57,59);
$date = $odate->clone;
$new = $dts->next($date);
$date = make_datetime(1987,6,21,17,58,0);
dcomp($new, $date, "$desc next");
$new = $dts->next($date);
$date = make_datetime(1987,6,21,17,59,0);
dcomp($new, $date, "$desc next");
$new = $dts->next($date);
$date = make_datetime(1987,6,22,17,0,0);
dcomp($new, $date, "$desc next");

$date = $odate->clone;
$new = $dts->previous($date);
$date = make_datetime(1987,6,21,17,57,0);
dcomp($new, $date, "$desc prev");

# cron on assorted minutes
$desc = "assorted minutes";
$dts = DateTime::Event::Cron->from_cron(cron => '2,32 * * * *');
ok($dts, "$desc create");
$odate = make_datetime(1987,6,21,17,57,59);
$date = $odate->clone;
$new = $dts->next($date);
$date = make_datetime(1987,6,21,18,2,0);
dcomp($new, $date, "$desc next");
$new = $dts->next($date);
$date = make_datetime(1987,6,21,18,32,0);
dcomp($new, $date, "$desc next");
$new = $dts->next($date);
$date = make_datetime(1987,6,21,19,2,0);
dcomp($new, $date, "$desc next");

$date = $odate->clone;
$new = $dts->previous($date);
$date = make_datetime(1987,6,21,17,32,0);
dcomp($new, $date, "$desc prev");
$new = $dts->previous($date);
$date = make_datetime(1987,6,21,17,2,0);
dcomp($new, $date, "$desc prev");
$new = $dts->previous($date);
$date = make_datetime(1987,6,21,16,32,0);
dcomp($new, $date, "$desc prev");

# cron after 1:20am on saturday 26th October, 1985
# on sundays and tuesdays, or on the 11th, in March and November.
# every 37 minutes past 7pm
$desc = '*/37 19 11 3,11 0,2';
$dts = DateTime::Event::Cron->from_cron(cron => $desc);
ok($dts, "$desc create");
$odate = make_datetime(1985,10,26,1,20,0);
$date = $odate->clone;
$new = $dts->next($date);
$date = make_datetime(1985,11,3,19,0,0);
dcomp($new, $date, "$desc next");
$new = $dts->next($date);
$date = make_datetime(1985,11,3,19,37,0);
dcomp($new, $date, "$desc next");
$new = $dts->next($date);
$date = make_datetime(1985,11,5,19,0,0);
dcomp($new, $date, "$desc next");
$new = $dts->next($date);
$date = make_datetime(1985,11,5,19,37,0);
dcomp($new, $date, "$desc next");
$new = $dts->next($date);
$date = make_datetime(1985,11,10,19,0,0);
dcomp($new, $date, "$desc next");
$new = $dts->next($date);
$date = make_datetime(1985,11,10,19,37,0);
dcomp($new, $date, "$desc next");
$new = $dts->next($date);
$date = make_datetime(1985,11,11,19,0,0);
dcomp($new, $date, "$desc next");
$new = $dts->next($date);
$date = make_datetime(1985,11,11,19,37,0);
dcomp($new, $date, "$desc next");

for (1..10) {
  # skip nov 12, 17, 19, 24, 26
  $date = $dts->next($date);
}

$new = $dts->next($date);
$date = make_datetime(1986,3,2,19,0,0);
dcomp($new, $date, "$desc next");
$new = $dts->next($date);
$date = make_datetime(1986,3,2,19,37,0);
dcomp($new, $date, "$desc next");
$new = $dts->next($date);
$date = make_datetime(1986,3,4,19,0,0);
dcomp($new, $date, "$desc next");
$new = $dts->next($date);
$date = make_datetime(1986,3,4,19,37,0);
dcomp($new, $date, "$desc next");

$date = $odate->clone;
$new = $dts->previous($date);
$date = make_datetime(1985,3,31,19,37,0);
dcomp($new, $date, "$desc prev");
$new = $dts->previous($date);
$date = make_datetime(1985,3,31,19,0,0);
dcomp($new, $date, "$desc prev");
$new = $dts->previous($date);
$date = make_datetime(1985,3,26,19,37,0);
dcomp($new, $date, "$desc prev");
$new = $dts->previous($date);
$date = make_datetime(1985,3,26,19,0,0);
dcomp($new, $date, "$desc prev");

# a very infrequent cron job
$desc = "infrequent";
$dts = DateTime::Event::Cron->from_cron(cron => '0 13 29 2 *');
ok($dts, "$desc create");
$odate = make_datetime(1995,4,12,5,30,0);
$date = $odate->clone;
$new = $dts->next($date);
$date = make_datetime(1996,2,29,13,0,0);
dcomp($new, $date, "$desc next");
$new = $dts->next($date);
$date = make_datetime(2000,2,29,13,0,0);
dcomp($new, $date, "$desc next");
$new = $dts->next($date);
$date = make_datetime(2004,2,29,13,0,0);
dcomp($new, $date, "$desc next");

$date = $odate->clone;
$new = $dts->previous($date);
$date = make_datetime(1992,2,29,13,0,0);
dcomp($new, $date, "$desc prev");
$new = $dts->previous($date);
$date = make_datetime(1988,2,29,13,0,0);
dcomp($new, $date, "$desc prev");
$new = $dts->previous($date);
$date = make_datetime(1984,2,29,13,0,0);
dcomp($new, $date, "$desc prev");

# End of tests
