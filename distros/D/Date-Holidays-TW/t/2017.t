use Test2::V0;

use Date::Holidays::TW qw(is_tw_holiday tw_holidays);

is is_tw_holiday(2017, 4,   4), T(), '清明';
is is_tw_holiday(2017, 4,   5), F();
is is_tw_holiday(2017, 5,  30), T(), '端午';
is is_tw_holiday(2017, 10, 11), F();

done_testing;
