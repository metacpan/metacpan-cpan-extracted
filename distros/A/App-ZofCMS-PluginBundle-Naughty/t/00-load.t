use Test::More tests => 3;

BEGIN {
    use_ok('App::ZofCMS::Plugin::Base');
    use_ok('GD::SecurityImage');
	use_ok( 'App::ZofCMS::Plugin::Captcha' );
}

diag( "Testing App::ZofCMS::Plugin::Captcha $App::ZofCMS::Plugin::Captcha::VERSION, Perl $], $^X" );
