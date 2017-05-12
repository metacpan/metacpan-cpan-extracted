#!/usr/bin/perl -w
use strict;
use lib './lib';
use Test::More tests => 28;

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

my($odate, $date, $new, $dtc, $desc);

# check some weird dates...Feb 29, non leap year
$desc = "Feb 29 skip, non leap year";
$dtc = DateTime::Event::Cron->new('1 1 29 * *');
ok($dtc, "$desc create");
$odate = make_datetime(2001,2,14,15,0,0);
$date = $odate->clone;
$new = $dtc->next($date);
$date = make_datetime(2001,3,29,1,1,0);
dcomp($new, $date, "$desc next");
$new = $dtc->next($date);
$date = make_datetime(2001,4,29,1,1,0);
dcomp($new, $date, "$desc next");
$new = $dtc->next($date);
$date = make_datetime(2001,5,29,1,1,0);
dcomp($new, $date, "$desc next");

$date = $odate->clone;
$new = $dtc->previous($date);
$date = make_datetime(2001,1,29,1,1,0);
dcomp($new, $date, "$desc prev");
$new = $dtc->previous($date);
$date = make_datetime(2000,12,29,1,1,0);
dcomp($new, $date, "$desc prev");
$new = $dtc->previous($date);
$date = make_datetime(2000,11,29,1,1,0);
dcomp($new, $date, "$desc prev");

# Feb 29, leap year.
$desc = "Feb 29 hit, leap year";
$dtc = DateTime::Event::Cron->new('1 1 29 * *');
ok($dtc, "$desc create");
$odate = make_datetime(1996,2,14,15,0,0);
$date = $odate->clone;
$new = $dtc->next($date);
$date = make_datetime(1996,2,29,1,1,0);
dcomp($new, $date, "$desc next");
$new = $dtc->next($date);
$date = make_datetime(1996,3,29,1,1,0);
dcomp($new, $date, "$desc next");
$new = $dtc->next($date);
$date = make_datetime(1996,4,29,1,1,0);
dcomp($new, $date, "$desc next");

$date = $odate->clone;
$new = $dtc->previous($date);
$date = make_datetime(1996,1,29,1,1,0);
dcomp($new, $date, "$desc prev");
$new = $dtc->previous($date);
$date = make_datetime(1995,12,29,1,1,0);
dcomp($new, $date, "$desc prev");
$new = $dtc->previous($date);
$date = make_datetime(1995,11,29,1,1,0);
dcomp($new, $date, "$desc prev");

# cron on 31st of the month, set date to february in a nonleap year
$desc = "Feb 31 skip, non leap year";
$dtc = DateTime::Event::Cron->new('1 1 31 * *');
ok($dtc, "$desc create");
$odate = make_datetime(2001,2,14,15,0,0);
$date = $odate->clone;
$new = $dtc->next($date);
$date = make_datetime(2001,3,31,1,1,0);
dcomp($new, $date, "$desc next");
$new = $dtc->next($date);
$date = make_datetime(2001,5,31,1,1,0);
dcomp($new, $date, "$desc next");
$new = $dtc->next($date);
$date = make_datetime(2001,7,31,1,1,0);
dcomp($new, $date, "$desc next");

$date = $odate->clone;
$new = $dtc->previous($date);
$date = make_datetime(2001,1,31,1,1,0);
dcomp($new, $date, "$desc prev");
$new = $dtc->previous($date);
$date = make_datetime(2000,12,31,1,1,0);
dcomp($new, $date, "$desc prev");
$new = $dtc->previous($date);
$date = make_datetime(2000,10,31,1,1,0);
dcomp($new, $date, "$desc prev");

# cron on 1st of the month, set date to february in a nonleap year
$desc = "Mar 1 from Feb, non leap year";
$dtc = DateTime::Event::Cron->new('1 1 1 * *');
ok($dtc, "$desc create");
$odate = make_datetime(2001,2,14,15,0,0);
$date = $odate->clone;
$new = $dtc->next($date);
$date = make_datetime(2001,3,1,1,1,0);
dcomp($new, $date, "$desc next");
$new = $dtc->next($date);
$date = make_datetime(2001,4,1,1,1,0);
dcomp($new, $date, "$desc next");
$new = $dtc->next($date);
$date = make_datetime(2001,5,1,1,1,0);
dcomp($new, $date, "$desc next");

$date = $odate->clone;
$new = $dtc->previous($date);
$date = make_datetime(2001,2,1,1,1,0);
dcomp($new, $date, "$desc prev");
$new = $dtc->previous($date);
$date = make_datetime(2001,1,1,1,1,0);
dcomp($new, $date, "$desc prev");
$new = $dtc->previous($date);
$date = make_datetime(2000,12,1,1,1,0);
dcomp($new, $date, "$desc prev");

# End test
