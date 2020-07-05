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

# Royal stuff, this changes based on who has the throne and Sunday, Saturday,
# Monday logic.
ok(is_holiday(2020, 4, 27),  "Willempie");
ok(!is_holiday(2013, 4, 27), ".. but not when mommy had the throne");
ok(is_holiday(2013, 4, 30), ".. it was still on the last day of April");
ok(is_holiday(1989, 4, 29), ".. change of date for 1989");
ok(is_holiday(1978, 5, 1),  ".. but before it was celebrated on labor day");
ok(is_holiday(2014, 4, 26),  "Willem came early");

done_testing;
