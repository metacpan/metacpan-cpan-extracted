use Test2::V0;

use Date::Holidays::TW qw(is_tw_holiday tw_holidays);

is is_tw_holiday(2021, 2,  10), T();
is is_tw_holiday(2021, 2,  11), T();
is is_tw_holiday(2021, 2,  12), T();
is is_tw_holiday(2021, 2,  13), T();
is is_tw_holiday(2021, 2,  14), T();
is is_tw_holiday(2021, 4,   4), T(), '清明 + 兒童節';
is is_tw_holiday(2021, 4,   5), T();
is is_tw_holiday(2021, 6,  14), T(), '端午';
is is_tw_holiday(2021, 9,   3), F(), '';

done_testing;
