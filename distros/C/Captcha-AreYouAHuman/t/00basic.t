use Test::More tests => 3;

BEGIN {
  use_ok( 'Captcha::AreYouAHuman' );
}

diag( "Testing Captcha::AreYouAHuman $Captcha::AreYouAHuman::VERSION" );

ok( my $ayah = Captcha::AreYouAHuman->new(), 'Ayah object Created OK' );
isa_ok( $ayah, 'Captcha::AreYouAHuman' );

