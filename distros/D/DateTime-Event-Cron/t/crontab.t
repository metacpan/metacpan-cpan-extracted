#!/usr/bin/perl -w
use strict;
use lib './lib';
use Test::More tests => 9;

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

my($odate, $date, $new, $dts);
my(@dts, @set);

@dts = DateTime::Event::Cron->from_crontab(file => \*DATA);
is(scalar @dts, 4, 'load crontab');

$odate = make_datetime(2004,8,8,8,8,8);
$date = $odate->clone;
$new = $dts[0]->next($date);
$date = make_datetime(2004,8,8,9,1,0);
dcomp($new, $date, 'next');
$new = $dts[0]->previous($date);
$date = make_datetime(2004,8,8,8,1,0);
dcomp($new, $date, 'prev');

$date = $odate->clone;
$new = $dts[1]->next($date);
$date = make_datetime(2004,8,9,4,2,0);
dcomp($new, $date, 'next');
$new = $dts[1]->previous($date);
$date = make_datetime(2004,8,8,4,2,0);
dcomp($new, $date, 'prev');

$date = $odate->clone;
$new = $dts[2]->next($date);
$date = make_datetime(2004,8,15,4,22,0);
dcomp($new, $date, 'next');
$new = $dts[2]->previous($date);
$date = make_datetime(2004,8,8,4,22,0);
dcomp($new, $date, 'prev');

$date = $odate->clone;
$new = $dts[3]->next($date);
$date = make_datetime(2004,9,1,4,42,0);
dcomp($new, $date, 'next');
$new = $dts[3]->previous($date);
$date = make_datetime(2004,8,1,4,42,0);
dcomp($new, $date, 'prev');

# End of tests

__DATA__

SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=root
HOME=/

# run-parts
01 * * * * root run-parts /etc/cron.hourly
02 4 * * * root run-parts /etc/cron.daily
22 4 * * 0 root run-parts /etc/cron.weekly
42 4 1 * * root run-parts /etc/cron.monthly
