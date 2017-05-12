#!/usr/bin/perl

use warnings;
use strict;

use Test::More 'no_plan';

use Date::Piece qw(date centuries years months weeks days);

my $w7 = 7*weeks;
is($w7, '7weeks');
my $aw7 = $w7;
$aw7++;
is($aw7, '8weeks');
$aw7*=2;
is($aw7, '16weeks');
is($w7, '7weeks');
{
  my $fails = eval{$aw7/3};
  my $err = $@;
  like($err, qr/can only work in integer weeks/);
}
{
  my $fails = eval{4.1*weeks};
  my $err = $@;
  like($err, qr/can only work in integer weeks/);
}

my $m7 = 7*months;
is($m7, '7months');
my $am7 = $m7;
$am7++;
is($am7, '8months');
$am7*=2;
is($am7, '16months');
$am7/=2;
is($am7, '8months');
is($m7, '7months', 'untouched');
{
  my $fails = eval{$am7/3};
  my $err = $@;
  like($err, qr/can only work in integer months/);
}

my $y7 = 7*years;
is($y7, '7years');
my $ay7 = $y7;
$ay7++;
is($ay7, '8years');
$ay7*=2;
is($ay7, '16years');
$ay7/=2;
is($ay7, '8years');
is($y7, '7years', 'untouched');
{
  eval{$ay7/=3};
  my $err = $@;
  like($err, qr/can only work in integer years/);
  is($ay7, '8years');
}
{
  my $failed = eval{4.3*days};
  my $err = $@;
  like($err, qr/can only work in integer days at /);
}

my $date = date('2007-10-01');
is($date+7*days, '2007-10-08');
is($date-7*days, '2007-09-24');
is($date+$w7, '2007-11-19');
is($date+$m7, '2008-05-01');
is($date+$y7, '2014-10-01');
is($w7+$date, '2007-11-19');
is($m7+$date, '2008-05-01');
is($y7+$date, '2014-10-01');
is($date-$w7, '2007-08-13');
is($date-$m7, '2007-03-01');
is($date-$y7, '2000-10-01');
is($date+2*centuries, '2207-10-01');
is($date-2*centuries, '1807-10-01');

{
  my $v = eval{$y7-$date};
  my $err = $@;
  like($err, qr/^cannot subtract/);
}

# vim:ts=2:sw=2:et:sta
