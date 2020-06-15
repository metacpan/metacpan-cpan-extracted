use strict;
use warnings;
use Test::More 0.96;

use Date::Holidays::AW;

my $holidays = holidays(2019);
is(keys %$holidays, 12, "Twelve holidays found");

$holidays = holidays();
is(keys %$holidays, 12, "Twelve holidays found in the current year");

ok(is_holiday(2020, 3, 18), "Betico day is a holiday");

ok(is_holiday(2020, 2, 24), "Carnaval day is a holiday based on Easter");
ok(is_holiday(2020, 4, 12), 'Easter is "guessed" correctly');

ok(!is_holiday(1979, 11, 8), "My birthday isn't a holiday");

done_testing;
