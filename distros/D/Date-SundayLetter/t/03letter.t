use Test::More qw(no_plan);

BEGIN{ use_ok ('Date::SundayLetter'); }

is( letter(2000), 'BA', 'Letter in 2000' );
is( letter(2001), 'G', 'Letter in 2001' );
is( letter(2002), 'F', 'Letter in 2002' );
is( letter(2003), 'E', 'Letter in 2003' );
is( letter(2004), 'DC', 'Letter in 2004' );
is( letter(1612), 'AG', 'Letter in 1612' );
is( letter(1805), 'F', 'Letter in 1805' );
is( letter(2112), 'CB', 'Letter in 2112' );
is( letter(1727), 'E', 'Letter in 1727' );
is( letter(2419), 'F', 'Letter in 2419' );

