use strict;
use warnings;
use Test::More 0.96;

use Date::Holidays::BQ;
use DateTime;

my $holidays = holidays(2019);
is(keys %$holidays, 14, "Fourteen holidays found");

$holidays = holidays(2019, gov => 1);
is(keys %$holidays, 16, "Sixteen holidays found for government things");

is(is_holiday(2019, 5, 5, gov => 1, lang => 'nl'),
    'Bevrijdingsdag', "Gov is closed on that day");
is(is_holiday(2019, 6, 10, gov => 1, lang => 'nl'),
    'Tweede pinksterdag', "Gov is closed on that day");

$holidays = holidays();
is(keys %$holidays, 14, "Fourteen holidays found in the current year");

is(is_holiday(2020, 4,  30), "Dia di Rincon",  "Rincon day is a holiday");
is(is_holiday(2020, 9,  6),  "Dia di Boneiru", "Bonaire's flag day");
is(is_holiday(2020, 12, 15), "Dia di Reino",   "Kingdom day");

my $easter = is_holiday(2020, 4, 12);
is($easter, 'Pasku Grandi', 'Easter is "guessed" correctly in Papiamento');

$easter = is_holiday(2020, 4, 12, lang => 'en');
is($easter, 'Easter', 'Easter is "guessed" correctly in English');

$easter = is_holiday(2020,4,12, lang => 'nl');
is($easter, 'Pasen', "Found easter in the Dutch language");

$easter = is_holiday(2020,4,12, lang => 'de');
is($easter, 'Pasku Grandi', "Found easter in Papiamento language by default");

is(is_holiday(2022, 2, 27), "Prome dia di Carnaval", "First day of carnaval");

my $asuncion = is_holiday(2024,5,9, lang => 'pap');
is($asuncion, 'Dia di Asuncion', "39 days, not 40");

ok(!is_holiday(1979, 11, 8), "My birthday isn't a holiday");

# Royal stuff, this changes based on who has the throne and Sunday, Saturday,
# Monday logic.
ok(is_holiday(2020, 4, 27),  "Willempie");
ok(!is_holiday(2013, 4, 27), ".. but not when mommy had the throne");
ok(is_holiday(2013, 4, 30), ".. it was still on the last day of April");
ok(is_holiday(1989, 4, 29), ".. change of date for 1989");
ok(is_holiday(1978, 5, 1),  ".. but before it was celebrated on labor day");
ok(is_holiday(2014, 4, 26),  "Willem came early");

is(is_holiday_dt(DateTime->new(year => 2020, month => 4, day => 27)),
    "Dia di Rei", "Willem 2");

done_testing;
