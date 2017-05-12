use strict;
use warnings;
use Test::More;

plan tests => 77;

use Class::Date qw(localdate date);

$Class::Date::DST_ADJUST=1;

ok(1);

# Class::Date::new

my $date1 = Class::Date->new([2000,11,11,0,1,2]);
is $date1, "2000-11-11 00:01:02";

my $date2 = localdate [2000,10,5];
is $date2, "2000-10-05 00:00:00";

my $date3 = date({ 
  year => 2001, month => 03, day => 11, 
  hour =>   12,   min => 13, sec => 55
});
is $date3, "2001-03-11 12:13:55";

my $date4 = localdate({
  year => 2001, month => 03, day => 11
});
is $date4, "2001-03-11 00:00:00";

my $date5 = localdate("2001-2-21 13:11:10.123456");
is $date5, "2001-02-21 13:11:10";

my $date6 = localdate("2001-2-21 13:11");
is $date6, "2001-02-21 13:11";

my $date7 = localdate("2000-11-11 0:0:0");
is $date7, "2000-11-11";

my $date8 = localdate("2001011312220112");
is $date8, "2001-01-13 12:22:01";

my $date9 = localdate("2001-5-11");
is $date9, "2001-05-11 00:00:00";

my $date10 = $date9->new($date9);
is $date10, "2001-05-11";

# Class::Date::Rel::new

my $reldate1 = Class::Date::Rel->new('1D');
is $reldate1, "0000-00-01 00:00:00";

my $reldate2 = Class::Date::Rel->new('1Y 1M 15h 20m');
is $reldate2, "0001-01-00 15:20";

my $reldate3 = Class::Date::Rel->new('3Y 3M 5D 13h 20m 15s');
is $reldate3, "0003-03-05 13:20:15";

my $reldate4 = Class::Date::Rel->new({ year => 5, day => 7});
is $reldate4, "0005-00-07 00:00:00";

my $reldate5 = Class::Date::Rel->new({ 
  year => 9, month => 8,    day => 7,
  hour => 6, min   => 65,   sec => 55,
});
is $reldate5, "0009-08-07 07:05:55";

my $reldate6 = Class::Date::Rel->new([9,8,7,6,65,55]);
is $reldate6, "0009-08-07 07:05:55";

my $reldate7 = Class::Date::Rel->new("7-8-6 07:11:10");
is $reldate7, "0007-08-06 07:11:10";

my $reldate8 = $reldate5->new($reldate7);
is $reldate8, "7Y 8M 6D 7h 11m 10s";

# Class::Date::add

is $date1+$reldate1, "2000-11-12 00:01:02";
is $date7+$reldate3, "2004-02-16 13:20:15";
is $date1+"2Y",      "2002-11-11 00:01:02";
is $date1+"2-0-0",   "2002-11-11 00:01:02";

# Class::Date::subs
  
is $date1-$reldate1, "2000-11-10 00:01:02";
is $date7-$reldate3+$reldate3, $date7;
is $date3-$date1,   '120D 12h 12m 53s';
is $date1-'1D',     "2000-11-10 0:1:2";
is $date1-[0,0,1],  "2000-11-10 0:1:2";

# Class::Date Comparison

ok $date1 > $date2;
ok $date1 >= $date1;
ok ! ($date1<"2000-01-01");
ok ! ("2000-01-01">$date1);
is "2000-01-02" <=> $date1, -1;
is "2001-01-02" cmp $date1,  1 ;
is $date1 <=> "2000-01-02",  1;
is $date1 cmp "2001-01-02", -1;

# Class::Date::Rel Comparison

ok $reldate1 < $reldate2;
ok $reldate2 < '2Y';
ok '2Y'      < $reldate3;
is '2Y' <=> $reldate3, -1;
is $reldate3 <=> '2Y',  1;

# Class::Date field methods;

is $date1->year, 2000;
is $date1->mon,  11;
is $date1->day,  11;
is $date1->hour, 0;
is $date1->min,  1;
is $date1->sec,  2;

# Default values for hash initialization

my $date11 = Class::Date->new({ year => 2001 });
is $date11, "2001-01-01 00:00:00";

my $date12 = new Class::Date { month => 2   };
is $date12, "2000-02-01 00:00:00";

my $date13 = localdate [1998];
is $date13, "1998-01-01";

my $reldate9 = Class::Date::Rel->new( { year => 4 });
is $reldate9, "4-0-0 0:0:0";

my $reldate10 = Class::Date::Rel->new( { month => 5 });
is $reldate10, "0-5-0 0:0:0";

my ($y,$m,$d,$hh,$mm,$ss) = $date1->array;
is $y,  2000;
is $m,  11;
is $d,  11;
is $hh, 0;
is $mm, 1;
is $ss, 2;

# undef comparison
ok $date11 > undef() ? 1 : 0;
ok undef() > $date11 ? 0 : 1;
ok $date13 < undef() ? 0 : 1;
ok undef() < $date13 ? 1 : 0;

is $date1->month_begin,   "2000-11-01 00:01:02";
is $date1->month_end  ,   "2000-11-30 00:01:02";
is $date1->days_in_month, 30;
is $date2->days_in_month,31;
is $date5->days_in_month,28;

is $date1->truncate, "2000-11-11 00:00:00";
is $date1->trunc,    "2000-11-11 00:00:00";
is $date1,           "2000-11-11 00:01:02";

{
  local $Class::Date::MONTH_BORDER_ADJUST = 0;
  my $date11 = date("2001-05-31");
  is $date11+'4M', "2001-10-01";
  is $date11-'3M', "2001-03-03";
  $Class::Date::MONTH_BORDER_ADJUST = 1;
  is $date11+'4M', "2001-09-30";
  is $date11-'3M', "2001-02-28";
}

my $date14 = date("2001-12-18");
is $date14->days_in_month, 31;

is date([2001,11,17])->is_leap_year ? 1 : 0, 0;
is date([2004,03,05])->is_leap_year ? 1 : 0, 1;

