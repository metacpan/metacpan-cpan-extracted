use strict;
use Test::More tests => 8;

use Test::Exception;
use Date::Period::Human;

is_deeply([Date::Period::Human::_parse_mysql_date('2010-01-01 00:00:00')],
          ['2010','01','01','00','00','00']);

my @should_fail = (
    '010-01-01 00:00:00',
    '',
    undef,
    '01-01-2001 00:00:00',
    '01-01-2001 00:00',
    '2001-01-20 00:00',
);

for (@should_fail) {
    dies_ok { Date::Period::Human::_parse_mysql_date($_) };
}

is(
 Date::Period::Human->new({lang=>'en', today_and_now => [2010,3,5,10,15,0]})->human_readable('2010-03-08 10:15:00'),
 Date::Period::Human->new({lang=>'en', today_and_now => [2010,3,5,10,15,0]})->human_readable(1268043300),
 'parse SQL date vs. epoch');

