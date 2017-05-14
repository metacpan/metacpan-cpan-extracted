use Test::More qw(no_plan);

BEGIN {
    use_ok ('Acme::Time::Asparagus');
}

is( veggietime('12:00'), 'Cabbage', '12 is Cabbage' );
is( veggietime('1:00'), 'Tomato', '1 is Tomato' );
is( veggietime('8:13'),  'Carrot past Onion' );
is( veggietime('7:45'),  'Corn before Onion' );
is( veggietime('14:29'), 'Pumpkin past Eggplant' );

# Legacy stuff ...
warn ("\n\nYou'll get warnings here about deprecated language arguments. That's OK.\n\n");
is( veggietime('14:29', 'en_gb'), 'Pumpkin past Aubergine' );
warn ("\n\nAll done with the warnings.\n\n");
