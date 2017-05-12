#!/usr/bin/perl -w
use strict;
use lib './lib';
use Test::More qw(no_plan);

use DateTime;
use DateTime::Event::MultiCron;

sub make_datetime {
  @_ == 6 or die "Invalid argument count\n";
  DateTime->new( year => $_[0], month  => $_[1], day    => $_[2],
                 hour => $_[3], minute => $_[4], second => $_[5] );
}

sub dcomp { is(shift->datetime, shift->datetime, shift) }

my($odate, $date, $new, $dts, $dtc, $dtd, $desc);

$desc = 'every 2 or 5 mins';
$dts = DateTime::Event::MultiCron->from_multicron('*/5 * * * *','*/2 * * * *');
$odate = make_datetime(2007,7,26,18,21,0);
$date = make_datetime(2007,7,26,18,22,0);
$new=$dts->next($odate);
dcomp($new,$date,$desc);
$date = make_datetime(2007,7,26,18,24,0);
$new=$dts->next($new);
dcomp($new,$date,$desc);
$date = make_datetime(2007,7,26,18,25,0);
$new=$dts->next($new);
dcomp($new,$date,$desc);
$date = make_datetime(2007,7,26,18,26,0);
$new=$dts->next($new);
dcomp($new,$date,$desc);
$date = make_datetime(2007,7,26,18,28,0);
$new=$dts->next($new);
dcomp($new,$date,$desc);

$desc = 'every 5 on fri, every 2 on sat';
$dts = DateTime::Event::MultiCron->from_multicron('*/5 * * * 5','*/2 * * * 6');
$odate = make_datetime(2007,7,27,23,46,0);
$date = make_datetime(2007,7,27,23,50,0);
$new = $dts->next($odate);
dcomp($new,$date,$desc);
$date = make_datetime(2007,7,27,23,55,0);
$new = $dts->next($new);
dcomp($new,$date,$desc);
$date = make_datetime(2007,7,28,0,0,0);
$new = $dts->next($new);
dcomp($new,$date,$desc);
$date = make_datetime(2007,7,28,0,2,0);
$new = $dts->next($new);
dcomp($new,$date,$desc);
$date = make_datetime(2007,7,28,0,4,0);
$new = $dts->next($new);
dcomp($new,$date,$desc);
$date = make_datetime(2007,7,28,0,6,0);
$new = $dts->next($new);
dcomp($new,$date,$desc);
