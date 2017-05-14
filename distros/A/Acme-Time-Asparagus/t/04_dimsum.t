use Test::More qw(no_plan);

BEGIN {
    use_ok('Acme::Time::DimSum');
}

is( sushitime('7:45'),  'Sui Mai before Fried Won Ton' );
is( sushitime('14:29'), 'Spring Roll past Perl Ball' );
is( sushitime('12:00'), 'Pork Bun', '12 is Pork Bun' );
is( sushitime('1:00'),  'Potsticker', '1 is Potsticker' );
is( sushitime('8:13'),  'Custard Tart past Fried Won Ton' );
is( sushitime('14:29'), 'Spring Roll past Perl Ball' );

