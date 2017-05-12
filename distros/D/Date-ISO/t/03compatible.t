use Test::More qw(no_plan);

BEGIN { use_ok( 'Date::ISO' ); }

my ($year, $week, $day, $month);

($year, $week, $day ) = iso( 1971, 10, 25 );
is( $year, 1971, "iso - year");
is( $week, 43, "iso - week" );
is( $day, 1, "iso - week day" );

($year, $week, $day) = iso( 2001, 4, 28);
is($year, 2001, "iso - year" );
is($week, 17, "iso - week" );
is( $day, 6, "iso - day" );

($year, $week, $day) = iso( 2001, 8, 2 );
is( $year, 2001, "iso - year");
is( $week, 31, "iso - week");
is( $day, 4, "iso - day");

($year, $month, $day) = inverseiso( 2001, 31, 4 );
is( $year, 2001, 'inverseiso - year' );
is( $month, 8, 'inverseiso - month' );
is( $day,  2, 'inverseiso - day' );

$iso = Date::ISO->new( iso => '2001-W31-4', offset => 0 );
is($iso->iso ,  '2001-W31-4', 
    "Get what we started with.");
is( $iso->offset, 0, "Is the offset what we asked for?");

( $year, $month, $day ) = inverseiso( 2001, 17, 6 );
is( $year , 2001, "inverseiso - year" );
is( $month, 4, "inverseiso - month" );
is( $day, 28, "inverseiso - day" );

$iso = Date::ISO->new( iso => '2001-W17-6', offset => 0 );
is( $iso->iso, '2001-W17-6', "Get what we started with?");
is( $iso->offset, 0, "Is the offset what we asked for?");

