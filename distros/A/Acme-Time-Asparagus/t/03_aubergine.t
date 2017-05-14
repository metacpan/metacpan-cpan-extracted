use Test::More qw(no_plan);

BEGIN {
    use_ok ('Acme::Time::Aubergine');
}


is( veggietime('7:45'),  'Sweetcorn before Onion' );
is( veggietime('14:29'), 'Pumpkin past Aubergine' );

