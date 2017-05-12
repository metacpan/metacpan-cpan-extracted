use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Scalar';

ok Data::Object::Scalar->does('Data::Object::Role::Comparison');
ok Data::Object::Scalar->does('Data::Object::Role::Defined');
ok Data::Object::Scalar->does('Data::Object::Role::Detract');
ok Data::Object::Scalar->does('Data::Object::Role::Dumper');
ok Data::Object::Scalar->does('Data::Object::Role::Item');
ok Data::Object::Scalar->does('Data::Object::Role::Output');
ok Data::Object::Scalar->does('Data::Object::Role::Throwable');
ok Data::Object::Scalar->does('Data::Object::Role::Type');
ok Data::Object::Scalar->does('Data::Object::Role::Value');

can_ok 'Data::Object::Scalar', 'data';
can_ok 'Data::Object::Scalar', 'defined';
can_ok 'Data::Object::Scalar', 'detract';
can_ok 'Data::Object::Scalar', 'dump';
can_ok 'Data::Object::Scalar', 'eq';
can_ok 'Data::Object::Scalar', 'ge';
can_ok 'Data::Object::Scalar', 'gt';
can_ok 'Data::Object::Scalar', 'le';
can_ok 'Data::Object::Scalar', 'lt';
can_ok 'Data::Object::Scalar', 'methods';
can_ok 'Data::Object::Scalar', 'ne';
can_ok 'Data::Object::Scalar', 'new';
can_ok 'Data::Object::Scalar', 'print';
can_ok 'Data::Object::Scalar', 'roles';
can_ok 'Data::Object::Scalar', 'say';
can_ok 'Data::Object::Scalar', 'throw';
can_ok 'Data::Object::Scalar', 'type';

ok 1 and done_testing;
