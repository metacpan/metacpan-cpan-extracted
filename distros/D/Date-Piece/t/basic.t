#!/usr/bin/perl

use warnings;
use strict;

use Test::More 'no_plan';

use Date::Piece qw(today date);

my $today = Date::Piece->today;
ok($today, 'today');
{
  my $yesterday = $today->prev;
  ok($yesterday, 'yesterday');
  ok($today > $yesterday, 'compare');

  my $y2 = $today - 1;
  isa_ok($y2, 'Date::Piece');
  is($y2, $yesterday, 'subtract ok');

  my $y3 = today - 1; # no parse problem here
  isa_ok($y3, 'Date::Piece');
  is($y3, $yesterday, 'subtract ok');

}

{
  my $tomorrow = $today->next;
  ok($tomorrow, 'tomorrow');
  ok($tomorrow > $today, 'compare');

  my $t2 = $today + 1;
  isa_ok($t2, 'Date::Piece');
  is($t2, $tomorrow, 'add ok');

  my $t3 = today + 1; # no parse problem here
  isa_ok($t3, 'Date::Piece');
  is($t3, $tomorrow, 'add ok');
}


{
  my $time = Time::Piece->new;
  my $date = $time->date;
  isa_ok($date, 'Date::Piece');
  my $at = $date->at($time);
  is($time, $at, 'replicated');

  my $at2 = $date->at(
    join(':', $time->hour, $time->minute, $time->second)
  );
  is($time, $at2, 'replicated the hard way');
}

{
  my $dec1 = date('2007-12-01');
  my $time = $dec1->at('3600s');
  is($time->hour, 1);
  is($time->min, 0);
  is($time->sec, 0);
}
{
  my $dec1 = date('2007-12-01');
  my $time = $dec1->at('-3600s');
  is($time->hour, 23);
  is($time->min, 0);
  is($time->sec, 0);
}
{
  my $oct11 = date('2007-10-11');
  my $oct1 = $oct11->start_of_month;
  is($oct1, '2007-10-01');
  is($oct11->end_of_month, '2007-10-31');

  my $feb11 = date('2007-02-11');
  is($feb11->end_of_month, '2007-02-28');

  my $lfeb11 = date('2004-02-11');
  is($lfeb11->end_of_month, '2004-02-29');
  ok($lfeb11->leap_year, '2004 was a leap year');
}

{
  {
    eval {date('2007-02-29')};
    my $err = $@;
    ok($err and $err =~ m/^invalid date/);
  }
  {
    eval {date('2004-02-30')};
    my $err = $@;
    ok($err and $err =~ m/^invalid date/);
  }
}
{
  my $also = my $day = date('1980-03-12');
  $day+= 15;
  is($day->day, 27, '+=');
  $day+= 5;
  is($day, '1980-04-01');
  is($day - date('1980-03-10'), 22);
  $day+=20;
  is($day - date('1980-03-10'), 42);
  $day-=20;
  is($day, '1980-04-01', '-=');
  is($also, '1980-03-12', 'no ref weirdness');
}
{
  my $day = date('1987-12-18'); # perl's birthday
  is($day->add_years(20), '2007-12-18', 'perl turns 20');
}
{ # adding years in February
  my $day = date('1984-02-29');
  my $a1 = $day->add_years(1);
  is($a1, '1985-02-28');
  my $a2 = $day->add_years(-1);
  is($a2, '1983-02-28');
}
{
  # adding months on the 31st
  my $day = date('1953-10-31');
  my $a1 = $day->add_months(2);
  is($a1, '1953-12-31');
  my $a2 = $day->add_months(-4);
  is($a2, '1953-06-30');
  is($a2->add_months(-6), '1952-12-30');

  my $a3 = $a1->add_months(-12);
  is($a3, '1952-12-31');
  my $a4 = $a1->add_months(12);
  is($a4, '1954-12-31');
}

{ # start and end of the year
  my $day = date('1970-12-10');
  is($day->start_of_year, '1970-01-01');
  is($day->end_of_year, '1970-12-31');
}
{ # king of days, day of work, day of rest, yada, yada
  my $sat = date('2000-01-01');
  is($sat->day_of_week, 6, 'dow per localtime');
  is($sat->iso_dow, 5, 'dow per iso 8601');
  is($sat->iso_wday, 6, 'wday per iso 8601');

  my $sun = $sat+1;
  is($sun->day_of_week, 0, 'dow per localtime');
  is($sun->iso_dow, 6, 'dow per iso 8601');
  is($sun->iso_wday, 7, 'wday per iso 8601');

  my $mon = $sun+1;
  is($mon->day_of_week, 1, 'dow per localtime');
  is($mon->iso_dow, 0, 'dow per iso 8601');
  is($mon->iso_wday, 1, 'wday per iso 8601');
}

{
  my $d1 = date('2007-12-31');
  my $d2 = $d1+6;
  my @list = $d1->thru($d2);
  is(scalar(@list), 7);
  is($list[0], $d1);
  is($list[$_], $d1+$_) for(1..5);
  is($list[6], $d2);
  # backwards
  @list = $d2->thru($d1);
  is(scalar(@list), 7);
  is($list[0], $d2);
  is($list[$_], $d2-$_) for(1..5);
  is($list[6], $d1);
  # non-date
  @list = $d1->thru("$d2");
  is($list[0], $d1);
  is($list[$_], $d1+$_) for(1..5);
  is($list[6], $d2);
}


# vim:ts=2:sw=2:et:sta
