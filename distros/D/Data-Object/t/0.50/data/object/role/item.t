use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Role::Item';

can_ok 'Data::Object::Role::Item', 'data';
can_ok 'Data::Object::Role::Item', 'detract';
can_ok 'Data::Object::Role::Item', 'methods';
can_ok 'Data::Object::Role::Item', 'roles';
can_ok 'Data::Object::Role::Item', 'throw';
can_ok 'Data::Object::Role::Item', 'type';

ok 1 and done_testing;
