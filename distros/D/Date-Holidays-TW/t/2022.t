use Test2::V0;

use Date::Holidays::TW qw(is_tw_holiday tw_holidays);

is is_tw_holiday(2022, 1,  29), T();
is is_tw_holiday(2022, 1,  30), T();
is is_tw_holiday(2022, 1,  31), T();
is is_tw_holiday(2022, 2,   1), T();
is is_tw_holiday(2022, 2,   2), T();
is is_tw_holiday(2022, 2,   3), T();
is is_tw_holiday(2022, 2,   4), T();
is is_tw_holiday(2022, 2,   5), T();

is is_tw_holiday(2022, 4,   5), T(), '清明';
is is_tw_holiday(2022, 4,   4), T(), '兒童節';
is is_tw_holiday(2022, 6,   3), T(), '端午';
is is_tw_holiday(2022, 9,   9), T();

done_testing;
