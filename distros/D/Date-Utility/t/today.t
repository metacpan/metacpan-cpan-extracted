use Test::Most 0.22 (tests => 6);
use Test::NoWarnings;
use Test::MockTime qw(:all);
use Date::Utility;

set_absolute_time(1302147038);
my $today = Date::Utility->today;
is $today,                              Date::Utility->today,     "Date::Utility->today returned the same object";
is $today->datetime_yyyymmdd_hhmmss_TZ, "2011-04-07 00:00:00GMT", "it is 00:00 at Apr 7 2011";
my $first_second_of_the_day = $today->epoch;
my $last_second_of_the_day  = $today->epoch + 86399;
set_fixed_time($last_second_of_the_day);
is(Date::Utility->today->datetime_yyyymmdd_hhmmss_TZ, "2011-04-07 00:00:00GMT", "still 00:00 at Apr 7 2011");
set_fixed_time($last_second_of_the_day + 1);
is(Date::Utility->today->datetime_yyyymmdd_hhmmss_TZ, "2011-04-08 00:00:00GMT", "and now it is tomorrow");
set_fixed_time($first_second_of_the_day - 1);
is(Date::Utility->today->datetime_yyyymmdd_hhmmss_TZ, "2011-04-06 00:00:00GMT", "and now it is yesterday");
