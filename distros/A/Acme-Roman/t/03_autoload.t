
use Test::More no_plan => 1;

BEGIN { use_ok( 'Acme::Roman' ); }

ok( defined &AUTOLOAD, 'autoload was defined' );

ok( X );
isa_ok( X, 'Acme::Roman' );
is( abs X, 10 );
my $x = X;
is( "$x", 'X' );

is( abs I+II, 3 );
my $iii = I+II;
is( "$iii", 'III' );
