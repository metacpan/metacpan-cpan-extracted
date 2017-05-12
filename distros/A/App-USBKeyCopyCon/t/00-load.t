#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::USBKeyCopyCon' );
}

diag( "Testing App::USBKeyCopyCon $App::USBKeyCopyCon::VERSION, Perl $], $^X" );
