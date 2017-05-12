# t/004_config.t

use Test::More tests => 1;
use Alien::PNG;

like( Alien::PNG->get_header_version('png.h'), qr/([0-9]+\.)*[0-9]+/, "Testing png.h" );

diag 'Core version: '.Alien::PNG->get_header_version('png.h');
