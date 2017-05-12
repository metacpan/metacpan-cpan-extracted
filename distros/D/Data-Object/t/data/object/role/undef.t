use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Role::Undef';

can_ok 'Data::Object::Role::Undef', 'data';
can_ok 'Data::Object::Role::Undef', 'defined';
can_ok 'Data::Object::Role::Undef', 'detract';
can_ok 'Data::Object::Role::Undef', 'dump';
can_ok 'Data::Object::Role::Undef', 'eq';
can_ok 'Data::Object::Role::Undef', 'ge';
can_ok 'Data::Object::Role::Undef', 'gt';
can_ok 'Data::Object::Role::Undef', 'le';
can_ok 'Data::Object::Role::Undef', 'lt';
can_ok 'Data::Object::Role::Undef', 'methods';
can_ok 'Data::Object::Role::Undef', 'ne';
can_ok 'Data::Object::Role::Undef', 'print';
can_ok 'Data::Object::Role::Undef', 'roles';
can_ok 'Data::Object::Role::Undef', 'say';
can_ok 'Data::Object::Role::Undef', 'throw';
can_ok 'Data::Object::Role::Undef', 'type';

ok 1 and done_testing;
