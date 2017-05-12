# Test cases for DateStamp module.
# $Id: DateStamp.t 2 2005-11-30 02:30:55Z Todd Wylie $
use strict;
use warnings;
use Test::More tests => 44;

BEGIN { use_ok('DateStamp') }; 

# Create DATE object:
my $date_obj = DateStamp->new();

# Return year tests:
my ($short_year, $long_year);
ok(
   $short_year = $date_obj->return_year(length=>'short'), 
   "return_year: short = $short_year"
   );
ok(
   $long_year  = $date_obj->return_year(length=>'long'), 
   "return_year: long = $long_year"
   );
like(
     $short_year, qr/\d{2}/, 
     "return_year: digit check (short)"
     );
like(
     $long_year,  qr/\d{4}/, 
     "return_year: digit check (long)"
     );

# Return month tests:
my ($month_num, $month_short, $month_long);
ok(
   $month_num   = $date_obj->return_month(format=>'numeric'), 
   "return_month: numeric = $month_num"
   );
ok(
   $month_short = $date_obj->return_month(format=>'alpha', length=>'short'), 
   "return_month: short = $month_short"
   );
ok(
   $month_long  = $date_obj->return_month(format=>'alpha', length=>'long'), 
   "return_month: long = $month_long"
   );
like(
     $month_num,   qr/\d{2}/, 
     "return_month: digit check"
     );
like(
     $month_short, qr/\w{3}/, 
     "return_month: alpha check (short)"
     );
like(
     $month_long,  qr/\w+/,
     "return_month: alpha check (long)"
     );

# Return day tests:
my ($day_num, $day_short, $day_long);
ok(
   $day_num   = $date_obj->return_day(format=>'numeric'), 
   "return_day: numeric = $day_num"
   );
ok(
   $day_short = $date_obj->return_day(format=>'alpha', length=>'short'), 
   "return_day: short = $day_short"
   );
ok(
   $day_long = $date_obj->return_day(format=>'alpha', length=>'long'), 
   "return_day: long = $day_long"
   );
like(
     $day_num, qr/\d+/, 
     "return_day: digit check"
     ); 
like(
     $day_short, qr/\w{3}/,  
     "return_day: alpha check (short)"
     );
like(
     $day_long, qr/\w+/,    
     "return_day: alpha check (long)"
     );

# Return timestamp tests:
my ($civ_short, $civ_long, $mil_short, $mil_long, $localtime);
ok(
   $civ_short = $date_obj->return_time(format=>'12', length=>'short'), 
   "return_time: civilian check (short) = $civ_short"
   );
ok(
   $civ_long = $date_obj->return_time(format=>'12', length=>'long'), 
   "return_time: civilian check (long) = $civ_long"
   );
ok(
   $mil_short = $date_obj->return_time(format=>'24', length=>'short'), 
   "return_time: military check (short) = $mil_short"
   );
ok(
   $mil_long = $date_obj->return_time(format=>'24', length=>'long'), 
   "return_time: military check (long) = $mil_long"
   );
ok(
   $localtime = $date_obj->return_time(format=>'localtime'), 
   "return_time: localtime = $localtime"
   );
like(
     $civ_short, qr/\d\:\d{2}\s[ap]\.m\./, 
     "return_time: civilian string eval (short)"
     );
like(
     $civ_long, qr/\d\:\d{2}\:\d{2}\s[ap]\.m\./, 
     "return_time: civilian string eval (long)"
     );
like(
     $mil_short, qr/\d\d\:\d{2}/, 
     "return_time: military string eval (short)"
     );
like(
     $mil_long, qr/\d\d\:\d{2}\:\d{2}/, 
     "return_time: military string eval (long)"
     );
like(
     $localtime, qr/\w{3}\s\w{3}\s\d{2}\s\d{2}\:\d{2}\:\d{2}\s\d{4}/, 
     "return_time: string eval (localtime)"
     );

# Return date tests:
my ($yyyymmdd, $yyyymmdd_glued, $mmddyyyy, $mmddyyyy_glued, $month_day_year, $mon_day_year, $weekday_month_day_year, $month_day, $mon_day);
ok(
   $yyyymmdd = $date_obj->return_date(format=>'yyyymmdd'), 
   "return_date: yyyymmdd check = $yyyymmdd"
   );
ok(
   $yyyymmdd_glued = $date_obj->return_date(format=>'yyyymmdd', glue=>'-'), 
   "return_date: yyyymmdd check = $yyyymmdd_glued"
   );
ok(
   $mmddyyyy = $date_obj->return_date(format=>'mmddyyyy'), 
   "return_date: mmddyyyy check = $mmddyyyy"
   );
ok(
   $mmddyyyy_glued = $date_obj->return_date(format=>'mmddyyyy', glue=>'-'), 
   "return_date: mmddyyyy check = $mmddyyyy_glued"
   );
ok(
   $month_day_year = $date_obj->return_date(format=>'month-day-year'), 
   "return_date: month-day-year check = $month_day_year"
   );
ok(
   $mon_day_year = $date_obj->return_date(format=>'mon-day-year'), 
   "return_date: mon-day-year check = $mon_day_year"
   );
ok(
   $weekday_month_day_year = $date_obj->return_date(format=>'weekday-month-day-year'), 
   "return_date: weekday-month-day-year check = $weekday_month_day_year"
   );
ok(
   $month_day = $date_obj->return_date(format=>'month-day'), 
   "return_date: month-day check = $month_day"
   );
ok(
   $mon_day = $date_obj->return_date(format=>'mon-day'), 
   "return_date: mon-day check = $mon_day"
   );
like(
     $yyyymmdd, qr/\d{8}/, 
     "return_date: yyyymmdd eval"
     );
like(
     $yyyymmdd_glued, qr/\d{4}\S\d{2}\S\d{2}/, 
     "return_date: yyyymmdd_glued eval"
     );
like(
     $mmddyyyy, qr/\d{8}/, 
     "return_date: mmddyyyy eval"
     );
like(
     $mmddyyyy_glued, qr/\d{2}\S\d{2}\S\d{4}/, 
     "return_date: mmddyyyy_glued eval"
     );
like(
     $month_day_year, qr/\w+\s\d{2}\,\s\d{4}/, 
     "return_date: month_day_year eval"
     );
like(
     $weekday_month_day_year, qr/\w+\,\s\w+\s\d{2}\,\s\d{4}/, 
     "return_date: weekday_month_day_year eval"
     );
like(
     $month_day, qr/\w+\s\d{2}/, 
     "return_date: month_day eval"
     );
like(
     $mon_day, qr/\w{3}\s\d{2}/, 
     "return_date: mon_day eval"
     );
