use strict;
use warnings;
use Test::More;

use Alien::libuv;

diag "Install type: ".Alien::libuv->install_type;

pass 'OK';

done_testing();
