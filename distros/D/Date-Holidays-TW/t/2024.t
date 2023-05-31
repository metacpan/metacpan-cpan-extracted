use Test2::V0;

use Date::Holidays::TW qw(is_tw_holiday tw_holidays);

is is_tw_holiday(2024, 1,  1), T();
is is_tw_holiday(2024, 2,  7), F();
is is_tw_holiday(2024, 2,  8), T(), '小年夜';
is is_tw_holiday(2024, 4,  3), F();
is is_tw_holiday(2024, 4,  4), T(), '清明 / 兒童節';
is is_tw_holiday(2024, 4,  5), T(), '補假';
is is_tw_holiday(2024, 6, 22), T(), '端午';
is is_tw_holiday(2024, 9, 29), T(), '中秋';

done_testing;
