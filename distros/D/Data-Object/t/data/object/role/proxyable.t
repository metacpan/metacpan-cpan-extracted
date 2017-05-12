use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Role::Proxyable';

can_ok 'Data::Object::Role::Proxyable', 'AUTOLOAD';
can_ok 'Data::Object::Role::Proxyable', 'DESTROY';

ok 1 and done_testing;
