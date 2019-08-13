use strict;
use Test::More tests => 2;

use_ok('Bundle::Maintainer::MHASCH');
ok(Bundle::Maintainer::MHASCH->VERSION);
