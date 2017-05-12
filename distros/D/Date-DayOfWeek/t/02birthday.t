use Test::More qw(no_plan);

BEGIN { use_ok( 'Date::DayOfWeek::Birthday' ); }

# My Birthday - Monday
ok( birthday( 25, 10, 1971 ) eq "Monday's child is fair of face.",
    "Presumably, I'm fair of face." );

# Jean Le Febre born - Tuesday
ok( birthday( 9, 4, 1652 ) eq "Tuesday's child is full of grace.",
    "Jean Le Febre was full of grace." );

# Johann Carl Friedrich Gauss born - Wednesday
ok( birthday( 30, 4, 1777 ) eq "Wednesday's child is full of woe.",
    "Gauss, full of woe? Really?" );

# Initial public release of Linux - Saturday
ok( birthday( 5, 10, 1991 ) eq "Saturday's child works hard for his living.",
    "Linux works hard for its living");

