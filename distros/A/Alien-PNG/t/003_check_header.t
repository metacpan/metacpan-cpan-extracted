# t/003_check_headers.t - test check_header() functionality

use Test::More tests => 2;
use Alien::PNG;

diag("Testing basic headers png.h + pngconf.h");
is( Alien::PNG->check_header('png.h'),              1, "Testing availability of 'png.h'" );
is( Alien::PNG->check_header('png.h', 'pngconf.h'), 1, "Testing availability of 'png.h, pngconf.h'" );
