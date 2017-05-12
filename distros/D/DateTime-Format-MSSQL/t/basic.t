use strict;
use warnings;
use DateTime::Format::MSSQL;

use Test::More;

ok((my $dt = DateTime::Format::MSSQL->parse_datetime(
    '2004-08-21 14:36:48.080'
)), 'parsed datetime');

is $dt->year, 2004, 'year';
is $dt->month, 8, 'month';
is $dt->day, 21, 'day';
is $dt->hour, 14, 'hour';
is $dt->minute, 36, 'minute';
is $dt->second, 48, 'second';
is $dt->millisecond, 80, 'millisecond';

ok((my $formatted = DateTime::Format::MSSQL->format_datetime($dt)),
    'formatted datetime');

is $formatted, '2004-08-21 14:36:48.080', 'formatted datetime correctly';

ok((my $dtz = DateTime::Format::MSSQL->new(
   time_zone => 'America/Chicago',
)->parse_datetime(
    '2004-08-21 14:36:48.080'
)), 'parsed datetime');

is $dtz->year, 2004, 'year';
is $dtz->month, 8, 'month';
is $dtz->day, 21, 'day';
is $dtz->hour, 14, 'hour';
is $dtz->minute, 36, 'minute';
is $dtz->second, 48, 'second';
is $dtz->millisecond, 80, 'millisecond';
is $dtz->time_zone->name, 'America/Chicago', 'time_zone';

done_testing;
