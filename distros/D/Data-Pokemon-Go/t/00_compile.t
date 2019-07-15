use strict;
use Test::More 0.98 tests => 2;

use lib './lib';

use_ok('Data::Pokemon::Go');                                    # 1
new_ok('Data::Pokemon::Go');                                    # 2

done_testing();
