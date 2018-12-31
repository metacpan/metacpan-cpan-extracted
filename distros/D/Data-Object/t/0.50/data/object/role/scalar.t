use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Role::Scalar';

can_ok 'Data::Object::Role::Scalar', 'data';
can_ok 'Data::Object::Role::Scalar', 'defined';
can_ok 'Data::Object::Role::Scalar', 'detract';
can_ok 'Data::Object::Role::Scalar', 'dump';
can_ok 'Data::Object::Role::Scalar', 'eq';
can_ok 'Data::Object::Role::Scalar', 'ge';
can_ok 'Data::Object::Role::Scalar', 'gt';
can_ok 'Data::Object::Role::Scalar', 'le';
can_ok 'Data::Object::Role::Scalar', 'lt';
can_ok 'Data::Object::Role::Scalar', 'methods';
can_ok 'Data::Object::Role::Scalar', 'ne';
can_ok 'Data::Object::Role::Scalar', 'print';
can_ok 'Data::Object::Role::Scalar', 'roles';
can_ok 'Data::Object::Role::Scalar', 'say';
can_ok 'Data::Object::Role::Scalar', 'throw';
can_ok 'Data::Object::Role::Scalar', 'type';

ok 1 and done_testing;
