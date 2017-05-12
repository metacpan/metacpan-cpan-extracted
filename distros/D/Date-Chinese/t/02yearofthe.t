use Test::More qw(no_plan);

BEGIN{ use_ok( 'Date::Chinese' ); }

is( yearofthe( 1999 ), "Year of the hare, earth", 
    "1999 - Year of the hare, earth");
is( yearofthe( 2000 ), "Year of the dragon, metal",
    "2000 - Year of the dragon, metal" );
is( yearofthe( 2001 ), "Year of the snake, metal",
    "2001 - Year of the snake, metal" );
is( yearofthe( 2002 ), "Year of the horse, water",
    "2002 - Year of the horse, water" );
is( yearofthe( 2003 ), "Year of the sheep, water",
    "2003 - Year of the sheep, water" );
is( yearofthe( 2004 ), "Year of the monkey, wood",
    "2004 - Year of the monkey" );
is( yearofthe( 2005 ), "Year of the fowl, wood",
    "2005 - Year of the fowl" );
is( yearofthe( 2006 ), "Year of the dog, fire",
    "2006 - Year of the dog" );
is( yearofthe( 2007 ), "Year of the pig, fire",
    "2006 - Year of the pig" );
is( yearofthe( 2008 ), "Year of the rat, earth",
    "2006 - Year of the rat" );
is( yearofthe( 2009 ), "Year of the ox, earth",
    "2006 - Year of the ox" );
is( yearofthe( 2010 ), "Year of the tiger, metal",
    "2006 - Year of the tiger" );
