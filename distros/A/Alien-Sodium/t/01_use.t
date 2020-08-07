use strict;
use warnings;
use Test::More;

use Alien::Sodium;

diag "Install type: ".Alien::Sodium->install_type;

pass 'OK';

done_testing();
