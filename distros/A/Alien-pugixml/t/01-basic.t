use strict;
use warnings;
use Test::More;
use Test::Alien;
use Alien::pugixml;

alien_ok 'Alien::pugixml';

diag 'cflags: ' . Alien::pugixml->cflags;
diag 'libs: ' . Alien::pugixml->libs;
diag 'install_type: ' . Alien::pugixml->install_type;

done_testing;
