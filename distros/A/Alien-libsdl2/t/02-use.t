use strict;
use warnings;
use Test::More;

use Alien::libsdl2;

diag "Install type: " . Alien::libsdl2->install_type;

pass 'OK';

done_testing();
