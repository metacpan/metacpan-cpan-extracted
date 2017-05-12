use strict;
use warnings;
use strict;
use warnings;
use utf8;

use lib 't/lib';

use T qw( run_tests_from_data test_datetime_object );
use Test::More 0.96;
use Test::Fatal;

use DateTime::Format::Strptime;

run_tests_from_data( \*DATA );

done_testing();

__DATA__
[Leading and trailing space]
%Y%m%d
  20151222
skip round trip
year => 2015
month => 12
day => 22

[Olson time zone in upper case]
%Y %O
2015 AMERICA/NEW_YORK
skip round trip
year => 2015
time_zone_long_name => America/New_York

[Olson time zone in lower case]
%Y %O
2015 america/new_york
skip round trip
year => 2015
time_zone_long_name => America/New_York

[Olson time zone in random case]
%Y %O
2015 amERicA/new_YORK
skip round trip
year => 2015
time_zone_long_name => America/New_York

[Month name match is not too greedy]
%d%b%y
15Aug07
year  => 2007
month => 8
day   => 15

[Trailing text after match]
%Y-%m-%d
2016-01-13 in the afternoon
skip round trip
year  => 2016
month => 1
day   => 13

[Leading text before match]
%Y-%m-%d
in the afternoon of 2016-01-13
skip round trip
year  => 2016
month => 1
day   => 13

[%Y.suffix]
%Y
2016.suffix
skip round trip
year => 2016

[%Y-%m-%d.suffix]
%Y-%m-%d
2016-03-31.suffix
skip round trip
year  => 2016
month => 3
day   => 31

[prefix.year]
%Y
log.2016
skip round trip
year => 2016

[prefix.date]
%Y-%m-%d
log.2016-03-31
skip round trip
year  => 2016
month => 3
day   => 31

[prefix.year.suffix]
%Y
cron.2016.log
skip round trip
year => 2016

[prefix.year.suffix with strict]
%Y
cron.2016.log
skip round trip
strict
year => 2016

[prefix.date.suffix]
%Y-%m-%d
cron.2016-03-31.log
skip round trip
year  => 2016
month => 3
day   => 31

[prefix.date.suffix with strict]
%Y-%m-%d
cron.2016-03-31.log
skip round trip
strict
year  => 2016
month => 3
day   => 31

[ISO8601 + Z with Z at end ignored]
%Y%m%d%H%M%S
20161214233712Z
skip round trip
year   => 2016
month  => 12
day    => 14
hour   => 23
minute => 37
second => 12
