use Test2::V0;

use Date::Holidays::TW qw(is_tw_holiday tw_holidays);

is is_tw_holiday(2025, 1,  1), T();
is is_tw_holiday(2025, 1, 27), T(), '小年夜';
is is_tw_holiday(2025, 4,  3), T(), '補假';
is is_tw_holiday(2025, 4,  4), T(), '清明 / 兒童節';
is is_tw_holiday(2025, 4,  5), T(), '星期六';
is is_tw_holiday(2025, 5, 30), T(), '補假';
is is_tw_holiday(2025, 5, 31), T(), '端午';
is is_tw_holiday(2025,10,  6), T(), '中秋';
is is_tw_holiday(2025,10, 24), T(), '補假';

done_testing;
