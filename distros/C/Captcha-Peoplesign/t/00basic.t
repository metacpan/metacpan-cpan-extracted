use Test::More tests => 3;

BEGIN {
  use_ok( 'Captcha::Peoplesign' );
}

diag( "Testing Captcha::Peoplesign $Captcha::Peoplesign::VERSION" );

ok( my $ps = Captcha::Peoplesign->new(), 'PS object Created OK' );
isa_ok( $ps, 'Captcha::Peoplesign' );
