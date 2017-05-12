use strict;
use warnings;

use Test::More tests => 3;

BEGIN { use_ok('Capstone', ':all'); }

ok(join('.',Capstone::version()) eq '3.0');

ok(Capstone::support(CS_ARCH_ALL));
