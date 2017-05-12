# t/003_check_headers.t - test check_header() functionality

use Test::More tests => 2;
use Alien::SDL;

diag("Testing basic headers SDL.h + SDL_version.h");
is( Alien::SDL->check_header('SDL.h'), 1, "Testing availability of 'SDL.h'" );
is( Alien::SDL->check_header( 'SDL.h', 'SDL_version.h' ),
    1, "Testing availability of 'SDL.h, SDL_version.h'" );
