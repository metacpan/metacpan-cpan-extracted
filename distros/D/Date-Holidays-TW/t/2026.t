use Test2::V0;

use Date::Holidays::TW qw(is_tw_holiday tw_holidays);

is is_tw_holiday(2026, 1,  1), T();
is is_tw_holiday(2026, 2, 15), T(), '小年夜';
is is_tw_holiday(2026, 4,  3), T(), '補假';
is is_tw_holiday(2026, 4,  4), T(), '兒童節';
is is_tw_holiday(2026, 4,  5), T(), '清明節';
is is_tw_holiday(2026, 6, 19), T(), '端午';
is is_tw_holiday(2026, 9, 25), T(), '中秋節';
is is_tw_holiday(2026,10, 25), T(), '臺灣光復暨金門古寧頭大捷紀念日';

done_testing;
