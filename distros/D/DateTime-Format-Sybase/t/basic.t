use strict;
use warnings;
use DateTime::Format::Sybase;

use Test::More tests => 10;

ok((my $dt = DateTime::Format::Sybase->parse_datetime(
    '2004-08-21 14:36:48.080'
)), 'parsed datetime');

is $dt->year, 2004, 'year';
is $dt->month, 8, 'month';
is $dt->day, 21, 'day';
is $dt->hour, 14, 'hour';
is $dt->minute, 36, 'minute';
is $dt->second, 48, 'second';
is $dt->millisecond, 80, 'millisecond';

ok((my $formatted = DateTime::Format::Sybase->format_datetime($dt)),
    'formatted datetime');

is $formatted, '08/21/2004 14:36:48.080', 'formatted datetime correctly';
