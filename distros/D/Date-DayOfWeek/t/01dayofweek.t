use Test::More qw(no_plan);

BEGIN { use_ok( 'Date::DayOfWeek' ); }

# Today - Wednesday
ok( dayofweek( 30, 5, 2001 ) == 3, "I wrote this test on a Wednesday" );

# Pearl Harbor - Sunday
ok( dayofweek( 7, 12, 1941 ) == 0, "Pearl Harbor was bombed on a Sunday" );

# My Birthday - Monday
ok( dayofweek( 25, 10, 1971 ) == 1, "I was born on a Monday" );

# Declaration of independence - Thursday
ok( dayofweek( 4, 7, 1776 ) == 4, 
    "The declaration of independence was signed on a Thursday");

# Martin Luther King - Tuesday
ok( dayofweek( 9, 4, 1968 ) == 2, 
    "Martin Luther King, Jr., was shot on a Tuesday" );

# Marin Mersenne born - Thursday
ok( dayofweek( 8, 9, 1588 ) == 4,
    "Marin Mersenne was born on a Thursday" );

# Jean Le Febre born - Tuesday
ok( dayofweek( 9, 4, 1652 ) == 2,
    "Jean Le Febre was born on a Tuesday" );

# Leonhard Euler born - Friday
ok( dayofweek( 15, 4, 1707 ) == 5,
    "Leonhard Euler was born on a Friday" );

# Johann Carl Friedrich Gauss born - Wednesday
ok( dayofweek( 30, 4, 1777 ) == 3,
    "Johann Carl Friedrich Gauss was born on a Wednesday. Hard to imagine Gauss as a baby, isn't it?" );

# Nikolai Ivanovich Lobachevsky born - Saturday
ok( dayofweek( 1, 12, 1792 ) == 6,
    "Nikolai Ivanovich Lobachevsky was born on a Saturday");

# Pony Express opens for business - Tuesday
ok( dayofweek( 3, 4, 1860 ) == 2,
    "The Pony Express first opened for business on a Tuesday");

# Initial public release of Linux - Saturday
ok( dayofweek( 5, 10, 1991 ) == 6,
    "Linux was first released on a Saturday");

# Fixed leapyear bug on 9Oct2001
is( dayofweek( 3, 1, 2000 ), 1, "Jan 3 2000 was a Monday");
is( dayofweek( 25, 1, 2000 ), 2, "Jan 25 2000 was a Tuesday");
is( dayofweek( 18, 2, 2000 ), 5, "Feb 18 2000 was a Friday");
is( dayofweek( 29, 2, 2000 ), 2, "Feb 29 2000 was a Tuesday");
is( dayofweek( 22, 3, 2000 ), 3, "Mar 22 2000 was a Wednesday");

