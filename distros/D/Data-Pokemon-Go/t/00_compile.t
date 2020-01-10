use strict;
use warnings;
use utf8;
use Test::More 0.98 tests => 5;

use lib './lib';

use_ok('Data::Pokemon::Go');                                                # 1
new_ok('Data::Pokemon::Go');                                                # 2
use_ok('Data::Pokemon::Go::Pokemon');                                       # 3
my $pgp = new_ok('Data::Pokemon::Go::Pokemon');                             # 4

is $pgp->exists("バンギラス"), 1, "succeed to check for 'exists' method";    # 5

done_testing();
