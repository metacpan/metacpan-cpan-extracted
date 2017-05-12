package 
    DateTimeX::Lite;
use strict;

# don't want to override CORE::time()
sub DateTimeX::Lite::time { goto &hms }

*wday = \&day_of_week;
*dow  = \&day_of_week;
*doq = \&day_of_quarter;
*doy = \&day_of_year;
*datetime = \&iso8601;
*language = \&locale;
*mon = \&month;
*day_of_month = \&day;
*mday = \&day;
*min = \&minute;
*sec = \&second;
*date = \&ymd;

# deprecated
sub era { goto \&era_abbr };

1;

