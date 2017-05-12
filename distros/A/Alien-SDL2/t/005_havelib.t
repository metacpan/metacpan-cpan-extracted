# 005_havelib.t - test check_header() functionality

use Test::More tests => 1;
use Alien::SDL2;

is( Alien::SDL2->havelib('SDL2'), 1, "Havelib SDL2" );
