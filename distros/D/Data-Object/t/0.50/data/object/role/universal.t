use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Role::Universal';

can_ok 'Data::Object::Role::Universal', 'data';
can_ok 'Data::Object::Role::Universal', 'defined';
can_ok 'Data::Object::Role::Universal', 'detract';
can_ok 'Data::Object::Role::Universal', 'dump';
can_ok 'Data::Object::Role::Universal', 'eq';
can_ok 'Data::Object::Role::Universal', 'ge';
can_ok 'Data::Object::Role::Universal', 'gt';
can_ok 'Data::Object::Role::Universal', 'le';
can_ok 'Data::Object::Role::Universal', 'lt';
can_ok 'Data::Object::Role::Universal', 'methods';
can_ok 'Data::Object::Role::Universal', 'ne';
can_ok 'Data::Object::Role::Universal', 'print';
can_ok 'Data::Object::Role::Universal', 'roles';
can_ok 'Data::Object::Role::Universal', 'say';
can_ok 'Data::Object::Role::Universal', 'throw';
can_ok 'Data::Object::Role::Universal', 'type';

ok 1 and done_testing;
