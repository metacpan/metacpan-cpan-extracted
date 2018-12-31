use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Undef';

ok Data::Object::Undef->does('Data::Object::Role::Comparison');
ok Data::Object::Undef->does('Data::Object::Role::Defined');
ok Data::Object::Undef->does('Data::Object::Role::Detract');
ok Data::Object::Undef->does('Data::Object::Role::Dumper');
ok Data::Object::Undef->does('Data::Object::Role::Item');
ok Data::Object::Undef->does('Data::Object::Role::Output');
ok Data::Object::Undef->does('Data::Object::Role::Throwable');
ok Data::Object::Undef->does('Data::Object::Role::Type');
ok Data::Object::Undef->does('Data::Object::Role::Value');

can_ok 'Data::Object::Undef', 'data';
can_ok 'Data::Object::Undef', 'defined';
can_ok 'Data::Object::Undef', 'detract';
can_ok 'Data::Object::Undef', 'dump';
can_ok 'Data::Object::Undef', 'eq';
can_ok 'Data::Object::Undef', 'ge';
can_ok 'Data::Object::Undef', 'gt';
can_ok 'Data::Object::Undef', 'le';
can_ok 'Data::Object::Undef', 'lt';
can_ok 'Data::Object::Undef', 'methods';
can_ok 'Data::Object::Undef', 'ne';
can_ok 'Data::Object::Undef', 'new';
can_ok 'Data::Object::Undef', 'print';
can_ok 'Data::Object::Undef', 'roles';
can_ok 'Data::Object::Undef', 'say';
can_ok 'Data::Object::Undef', 'throw';
can_ok 'Data::Object::Undef', 'type';

ok 1 and done_testing;
