use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Universal';

ok Data::Object::Universal->does('Data::Object::Role::Comparison');
ok Data::Object::Universal->does('Data::Object::Role::Defined');
ok Data::Object::Universal->does('Data::Object::Role::Detract');
ok Data::Object::Universal->does('Data::Object::Role::Dumper');
ok Data::Object::Universal->does('Data::Object::Role::Item');
ok Data::Object::Universal->does('Data::Object::Role::Output');
ok Data::Object::Universal->does('Data::Object::Role::Throwable');
ok Data::Object::Universal->does('Data::Object::Role::Type');
ok Data::Object::Universal->does('Data::Object::Role::Value');

can_ok 'Data::Object::Universal', 'data';
can_ok 'Data::Object::Universal', 'defined';
can_ok 'Data::Object::Universal', 'detract';
can_ok 'Data::Object::Universal', 'dump';
can_ok 'Data::Object::Universal', 'eq';
can_ok 'Data::Object::Universal', 'ge';
can_ok 'Data::Object::Universal', 'gt';
can_ok 'Data::Object::Universal', 'le';
can_ok 'Data::Object::Universal', 'lt';
can_ok 'Data::Object::Universal', 'methods';
can_ok 'Data::Object::Universal', 'ne';
can_ok 'Data::Object::Universal', 'new';
can_ok 'Data::Object::Universal', 'print';
can_ok 'Data::Object::Universal', 'roles';
can_ok 'Data::Object::Universal', 'say';
can_ok 'Data::Object::Universal', 'throw';
can_ok 'Data::Object::Universal', 'type';

ok 1 and done_testing;
