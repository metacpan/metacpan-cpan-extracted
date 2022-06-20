use Test2::V0;

use Date::Holidays::TW qw(is_tw_holiday tw_holidays);

is is_tw_holiday(2023, 1,  29), T();
is is_tw_holiday(2023, 1,  30), F();
is is_tw_holiday(2023, 1,  31), F();
is is_tw_holiday(2023, 2,   1), F();
is is_tw_holiday(2023, 2,   2), F();
is is_tw_holiday(2023, 2,   3), F();
is is_tw_holiday(2023, 2,   4), F();
is is_tw_holiday(2023, 2,   5), T();
is is_tw_holiday(2023, 2,  18), F();

is is_tw_holiday(2023, 4,   3), T();
is is_tw_holiday(2023, 4,   4), T(), '兒童節';
is is_tw_holiday(2023, 4,   5), T(), '清明';

is is_tw_holiday(2023, 6,  22), T(), '端午';
is is_tw_holiday(2023, 9,  23), F();
is is_tw_holiday(2023, 9,  29), T(), '中秋';

done_testing;
