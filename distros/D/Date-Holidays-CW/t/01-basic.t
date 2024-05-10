use strict;
use warnings;
use Test::More 0.96;

use Date::Holidays::CW;
use DateTime;

my $holidays = holidays(2019);
is(keys %$holidays, 12, "Twelve holidays found");

$holidays = holidays();
is(keys %$holidays, 12, "Twelve holidays found in the current year");

is(is_holiday(2023, 2,  20), "Karnaval", "Karnaval's monday");
is(is_holiday(2023, 4, 27), "Dia di Rei",   "Kingdom day");

my $easter = is_holiday(2020, 4, 12);
is($easter, 'Pasku Grandi', 'Easter is "guessed" correctly in Papiamento');

$easter = is_holiday(2020, 4, 12, lang => 'en');
is($easter, 'Easter', 'Easter is "guessed" correctly in English');

my $asuncion = is_holiday(2024,5,9, lang => 'pap');
is($asuncion, 'Dia di Asuncion', "39 days, not 40");

is(is_holiday(2023, 5, 1), "Dia di Labor/Dia di Obrero", "Labor day");
is(is_holiday(2023, 10, 2), "Dia di Pais K\x{00f2}rsou", "Day of the country");
is(is_holiday(2023, 7, 2), "Dia di Himno i Bandera", "National day");

$easter = is_holiday(2020,4,12, lang => 'nl');
is($easter, 'Pasen', "Found easter in the Dutch language");

$easter = is_holiday(2020,4,12, lang => 'de');
is($easter, 'Pasku Grandi', "Found easter in Papiamento language by default");

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
