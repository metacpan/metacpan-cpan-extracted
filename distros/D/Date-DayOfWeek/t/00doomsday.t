
use Test::More qw(no_plan);

BEGIN { use_ok( 'Date::Doomsday' ); }

# 1900 - Wednesday
ok( doomsday(1900) == 3, "Doomsday 1900 is a Wednesday" );

# 2001 - Wednesday
ok( doomsday(2001) == 3, "Doomsday 2001 is a Wednesday" );

# 1856 - Tuesday
ok( doomsday(1865) == 2, "Doomsday 1856 is a Tuesday" );

# 2493 - Saturday
ok( doomsday(2493) == 6, "Doomsday 2493 is a Saturday" );

# 1584 - Wednesday
ok( doomsday(1584) == 3, "Doomsday 1584 is a Wednesday" );

# 1600 - Tuesday
ok( doomsday(1600) == 2, "Doomsday 1600 is a Tuesday" );

# 1700 - Sunday
ok( doomsday(1700) == 0, "Doomsday 1700 is a Sunday" );

# 1800 - Friday
ok( doomsday(1800) == 5, "Doomsday 1800 is a Friday" );

