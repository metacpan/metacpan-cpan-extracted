use Test2::V0;

use Date::Holidays::TW qw(is_tw_holiday tw_holidays);

is is_tw_holiday(2020, 2, 28), T();
is is_tw_holiday(2020, 11, 1), F();

is is_tw_holiday(2020, 4, 4), T(), "Qingming in 2020.";
is is_tw_holiday(2021, 4, 4), T(), "Qingming in 2021.";
is is_tw_holiday(2022, 4, 5), T(), "Qingming in 2022.";
is is_tw_holiday(2023, 4, 5), T(), "Qingming in 2023.";
is is_tw_holiday(2024, 4, 4), T(), "Qingming in 2024.";

is is_tw_holiday(2020, 10, 1), T(), "Mid-autum festival in 2020.";

done_testing;
