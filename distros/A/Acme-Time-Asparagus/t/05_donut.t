use Test::More qw(no_plan);

BEGIN {
    use_ok('Acme::Time::Donut');
}

is( donuttime('7:45'),  'Maple Donut before Blueberry Muffin' );
is( donuttime('14:29'), 'Powdered Sugar Donut past Chocolate Bar' );
is( donuttime('12:00'), 'Apple Turnover', '12 is Pork Bun' );
is( donuttime('1:00'),  'Glazed Donut', '1 is Potsticker' );
is( donuttime('8:13'),  'Cinnamon Roll past Blueberry Muffin' );
is( donuttime('14:29'), 'Powdered Sugar Donut past Chocolate Bar' );

