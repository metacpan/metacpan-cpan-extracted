use Test::More qw(no_plan);

BEGIN{ use_ok('Date::Passover') }

my ($month, $day) = roshhashanah(1996);
is($day, 14, "Rosh Hashanah 1996 is on the 14th");

($month, $day) = roshhashanah(2005);
is($day, 4, "Rosh Hashanah 2005 is on the 14th");

($month, $day) = roshhashanah(2016);
is($day, 3, "Rosh Hashanah 2016 is on the 14th");

($month, $day) = roshhashanah(1900);
is($day, 24, "Rosh Hashanah 1900 is on the 14th");

($month, $day) = roshhashanah(1978);
is($day, 2, "Rosh Hashanah 1978 is on the 14th");

($month, $day) = roshhashanah(2076);
is($day, 28, "Rosh Hashanah 2076 is on the 14th");



