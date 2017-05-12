use Test::More tests => 2;

BEGIN {
use_ok( 'Acme::Laugh' );
}

diag( "Testing Acme::Laugh $Acme::Laugh::VERSION" );

my $laugh = Acme::Laugh::laugh(10);
ok(length($laugh) > 10, "laugh length more or less correct");
diag( $laugh );
