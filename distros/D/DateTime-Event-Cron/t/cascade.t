#!/usr/bin/perl -w
use strict;
use lib './lib';
use Test::More tests => 21;

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

my($date, $new, $dts, $desc);

$desc = 'cascade minute to hour';
$dts = DateTime::Event::Cron->from_cron(cron => '30 10,14,18 * * *');
ok($dts, "$desc create");
$date = make_datetime(2003,1,1,14,40,0);
$new = $dts->next($date);
$date = make_datetime(2003,1,1,18,30,0);
dcomp($new, $date, "$desc next");
$date = make_datetime(2003,1,1,14,20,0);
$new = $dts->previous($date);
$date = make_datetime(2003,1,1,10,30,0);
dcomp($new, $date, "$desc prev");

$desc = "cascade hour to day";
$dts = DateTime::Event::Cron->from_cron(cron => '0 12 10,15,20 * *');
ok($dts, "$desc create");
$date = make_datetime(2003,1,15,15,0,0);
$new = $dts->next($date);
$date = make_datetime(2003,1,20,12,0,0);
dcomp($new, $date, "$desc next");
$date = make_datetime(2003,1,15,10,0,0);
$new = $dts->previous($date);
$date = make_datetime(2003,1,10,12,0,0);
dcomp($new, $date, "$desc prev");

$desc = "cascade hour to dow";
$dts = DateTime::Event::Cron->from_cron(cron => '0 12 * * 2,4,6');
ok($dts, "$desc create");
$date = make_datetime(2003,1,16,15,0,0);
$new = $dts->next($date);
$date = make_datetime(2003,1,18,12,0,0);
dcomp($new, $date, "$desc next");
$date = make_datetime(2003,1,16,10,0,0);
$new = $dts->previous($date);
$date = make_datetime(2003,1,14,12,0,0);
dcomp($new, $date, "$desc prev");

$desc = "cascade day to month";
$dts = DateTime::Event::Cron->from_cron(cron => '0 0 15 5,7,9 *');
ok($dts, "$desc create");
$date = make_datetime(2003,7,20,0,0,0);
$new = $dts->next($date);
$date = make_datetime(2003,9,15,0,0,0);
dcomp($new, $date, "$desc next");
$date = make_datetime(2003,7,10,0,0,0);
$new = $dts->previous($date);
$date = make_datetime(2003,5,15,0,0,0);
dcomp($new, $date, "$desc prev");

$desc = "cascade dow to month";
$dts = DateTime::Event::Cron->from_cron(cron => '0 0 * 5,7,9 3');
ok($dts, "$desc create");
$date = make_datetime(2003,7,31,0,0,0);
$new = $dts->next($date);
$date = make_datetime(2003,9,3,0,0,0);
dcomp($new, $date, "$desc next");
$date = make_datetime(2003,7,1,0,0,0);
$new = $dts->previous($date);
$date = make_datetime(2003,5,28,0,0,0);
dcomp($new, $date, "$desc prev");

$desc = "cascade month to year";
$dts = DateTime::Event::Cron->from_cron(cron => '0 0 1 7 *');
ok($dts, "$desc create");
$date = make_datetime(2003,8,30,0,0,0);
$new = $dts->next($date);
$date = make_datetime(2004,7,1,0,0,0);
dcomp($new, $date, "$desc next");
$date = make_datetime(2003,6,30,0,0,0);
$new = $dts->previous($date);
$date = make_datetime(2002,7,1,0,0,0);
dcomp($new, $date, "$desc prev");

$desc = "cascade ripple minute to year";
$dts = DateTime::Event::Cron->from_cron(cron => '20 10,14,18 5,10,15 5,7,9 *');
ok($dts, "$desc create");
$date = make_datetime(2003,9,15,18,30,0);
$new = $dts->next($date);
$date = make_datetime(2004,5,5,10,20,0);
dcomp($new, $date, "$desc next");
$date = make_datetime(2003,5,5,10,10,0);
$new = $dts->previous($date);
$date = make_datetime(2002,9,15,18,20,0);
dcomp($new, $date, "$desc prev");

# End test
