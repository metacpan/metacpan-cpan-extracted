use strict;
use warnings;

use Test::More tests => 29;
use Test::NoWarnings;
use Test::Exception;

use Date::Utility;

# New style is_epoch_timestamp
ok(!Date::Utility::is_epoch_timestamp('18-Jul-04'),           '18-Jul-04 not is_epoch_timestamp');
ok(!Date::Utility::is_epoch_timestamp('2010-01-03 12:34:56'), '2010-01-03 12:34:56 not is_epoch_timestamp');
ok(!Date::Utility::is_epoch_timestamp(undef),                 'undef not is_epoch_timestamp');
ok(Date::Utility::is_epoch_timestamp(100),                    '100 is_epoch_timestamp');
ok(Date::Utility::is_epoch_timestamp(-123456),                '-123456 is_epoch_timestamp');
ok(Date::Utility::is_epoch_timestamp(1278382486),             '1278382486 is_epoch_timestamp');

# New style  is_ddmmmyy
is(Date::Utility::is_ddmmmyy('2010-01-03 12:34:56'), undef, '2010-01-03 12:34:56 not is_ddmmmyy');
is(Date::Utility::is_ddmmmyy(undef),                 undef, 'undef not is_ddmmmyy');
is(Date::Utility::is_ddmmmyy('18-Jul-2004'),         undef, '18-Jul-2004 not is_ddmmmyy');
is(Date::Utility::is_ddmmmyy('18-Jul-04'),           1,     '18-Jul-04 is_ddmmmyy');
is(Date::Utility::is_ddmmmyy('12-Mon-99'),           1,     '12-Mon-99 is ddmmmyy');
is(Date::Utility::is_ddmmmyy('99-Jun-99'),           1,     '99-Jun-00 is_ddmmmyy');

# month_number_to_abbrev
is(Date::Utility::month_number_to_abbrev(01),    'Jan', '01 is Jan');
is(Date::Utility::month_number_to_abbrev(7),     'Jul', '7 is Jul');
is(Date::Utility::month_number_to_abbrev(00004), 'Apr', '00004 is Apr');
is(Date::Utility::month_number_to_abbrev(-1),    undef, '-1 is not a month');
is(Date::Utility::month_number_to_abbrev(0),     undef, '0 is not a month');
is(Date::Utility::month_number_to_abbrev(13),    undef, '13 is not a month');

# month_number_to_fullname
is(Date::Utility::month_number_to_fullname(01),    'January', '01 is January');
is(Date::Utility::month_number_to_fullname(7),     'July',    '7 is July');
is(Date::Utility::month_number_to_fullname(00004), 'April',   '00004 is April');
is(Date::Utility::month_number_to_fullname(-1),    undef,     '-1 is not a month');
is(Date::Utility::month_number_to_fullname(0),     undef,     '0 is not a month');
is(Date::Utility::month_number_to_fullname(13),    undef,     '13 is not a month');

# month_abbrev_to_number
is(Date::Utility::month_abbrev_to_number('Jun'),  6,     'Jun is 6');
is(Date::Utility::month_abbrev_to_number('MAY'),  5,     'MAY is 5');
is(Date::Utility::month_abbrev_to_number('dEC'),  12,    'dEC is 12');
is(Date::Utility::month_abbrev_to_number('July'), undef, 'July is not a month abbrev');

