use Test::More qw(no_plan);

BEGIN{ use_ok('Date::Passover') }

my ($month, $day) = passover(1996);

is( $month, 4, "Passover 1996 - Month" );
is( $day, 4, "Passover 1996 - Day");

