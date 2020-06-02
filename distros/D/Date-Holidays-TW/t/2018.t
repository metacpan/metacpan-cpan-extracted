use Test2::V0;

use Date::Holidays::TW qw(is_tw_holiday tw_holidays);

is is_tw_holiday(2018, 4, 5),  T(), '清明';
is is_tw_holiday(2018, 6, 18), T(), '端午';
is is_tw_holiday(2018, 10, 11),  F();

done_testing;
