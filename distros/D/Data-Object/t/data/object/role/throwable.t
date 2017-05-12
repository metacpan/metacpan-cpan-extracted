use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Role::Throwable';

can_ok 'Data::Object::Role::Throwable', 'throw';

ok 1 and done_testing;
