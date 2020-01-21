use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

my $date;

$date = Date->new("2013-09-05 03:04:05");

$date = Date->new("2013-09-05 13:14:15.123456+02");
is($date->to_string(Date::FORMAT_HMS), '13:14:15');
is($date->mksec, '123456');
is($date->gmtoff, 2 * 3600);

$date = Date->new("2013-09-05 23:04:05");
is($date->gmtoff, 14400);

tzset('America/New_York');
$date = Date->new("2013-09-05 23:45:56");
is($date->gmtoff, -14400);
tzset('Europe/Moscow');

$date = Date->new("2013-09-05 03:04:05");
is_deeply [$date->array], [2013,9,5,3,4,5];

$date = Date->new("2012-09-05 03:04:05");
is_deeply [$date->struct], [5,4,3,5,8,112,3,248,0];

$date = Date->new("2013-09-05 03:04:05");
is($date->month_begin_new, "2013-09-01 03:04:05");
is($date->month_end_new, "2013-09-30 03:04:05");
is($date->days_in_month, 30);

$date = Date->new("2013-08-05 03:04:05");
is($date->month_begin_new, "2013-08-01 03:04:05");
is($date, "2013-08-05 03:04:05");
is($date->month_end_new, "2013-08-31 03:04:05");
is($date, "2013-08-05 03:04:05");
is($date->days_in_month, 31);
$date->month_begin;
is($date, "2013-08-01 03:04:05");
$date->month_end;
is($date, "2013-08-31 03:04:05");

$date = Date->new("2013-02-05 03:04:05");
is($date->month_begin_new, "2013-02-01 03:04:05");
is($date->month_end_new, "2013-02-28 03:04:05");
is($date->days_in_month, 28);

$date = Date->new("2012-02-05 03:04:05");
is($date->month_begin_new, "2012-02-01 03:04:05");
is($date->month_end_new, "2012-02-29 03:04:05");
is($date->days_in_month, 29);

# now
my $now = Date::now();
ok(abs($now->epoch - time) <= 1);
# today
$date = Date::today();
is($date->year, $now->year);
is($date->month, $now->month);
is($date->day, $now->day);
is($date->hour, 0);
is($date->min, 0);
is($date->sec, 0);
# today_epoch
ok(abs(Date::today_epoch() - Date::today()->epoch) <= 1);

# date
$date = date(0);
is($date, "1970-01-01 03:00:00");
$date = date(1000000000);
is($date, "2001-09-09 05:46:40");
$date = Date::date_ymd(2012,02,20,15,16,17);
is($date, "2012-02-20 15:16:17", "line: ".__LINE__);
$date = Date::date_ymd(year => 2013, month => 06, day => 28, hour => 6, min => 6, sec => 6);
is($date, "2013-06-28 06:06:06");

# truncate
$date = Date::date "2013-01-26 06:47:29";
my $date2 = $date->truncated;
is($date, "2013-01-26 06:47:29");
is($date2, "2013-01-26 00:00:00");
$date->truncate;
is($date, "2013-01-26 00:00:00");

# to_number
is(int(date(123456789)), 123456789);

# set
$date->set(10);
is($date, "1970-01-01 03:00:10");
$date->set("2970-01-01 03:00:10");
is($date, "2970-01-01 03:00:10");
$date->set_ymd(2010,5,6,7,8,9);
is($date, "2010-05-06 07:08:09", "line: ".__LINE__);
$date->set_ymd(year => 2013, hour => 23);
is($date, "2013-01-01 23:00:00");

# dont core dump on bad values
$date = eval { date([]); 1 };
is($date, undef, "line: ".__LINE__);
$date = eval { date(\1); 1 };
is($date, undef, "line: ".__LINE__);
$date = eval { date({}); 1 };
is($date, undef, "line: ".__LINE__);

#strftime
$date = date(10);
is $date->strftime("%Y:%S"), "1970:10";

done_testing();
