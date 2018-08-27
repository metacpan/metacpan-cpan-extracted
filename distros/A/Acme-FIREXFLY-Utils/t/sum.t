use Test::More tests => 3;

BEGIN { use_ok( 'Acme::FIREXFLY::Utils' ) }

ok( defined Acme::FIREXFLY::Utils::sum, 'sum() is exported' );

is(Acme::FIREXFLY::Utils::sum(1..10), 55, 'The sum of 1 to 10 is 55');

