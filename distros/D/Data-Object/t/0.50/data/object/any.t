use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Any';

ok Data::Object::Any->does('Data::Object::Rule::Comparison');
ok Data::Object::Any->does('Data::Object::Rule::Defined');
ok Data::Object::Any->does('Data::Object::Role::Detract');
ok Data::Object::Any->does('Data::Object::Role::Dumper');
ok Data::Object::Any->does('Data::Object::Role::Output');
ok Data::Object::Any->does('Data::Object::Role::Throwable');
ok Data::Object::Any->does('Data::Object::Role::Type');

# no longer supported
# ok Data::Object::Any->does('Data::Object::Role::Value');

can_ok 'Data::Object::Any', 'data';
can_ok 'Data::Object::Any', 'defined';
can_ok 'Data::Object::Any', 'detract';
can_ok 'Data::Object::Any', 'dump';
can_ok 'Data::Object::Any', 'eq';
can_ok 'Data::Object::Any', 'ge';
can_ok 'Data::Object::Any', 'gt';
can_ok 'Data::Object::Any', 'le';
can_ok 'Data::Object::Any', 'lt';
can_ok 'Data::Object::Any', 'methods';
can_ok 'Data::Object::Any', 'ne';
can_ok 'Data::Object::Any', 'new';
can_ok 'Data::Object::Any', 'print';
can_ok 'Data::Object::Any', 'roles';
can_ok 'Data::Object::Any', 'say';
can_ok 'Data::Object::Any', 'throw';
can_ok 'Data::Object::Any', 'type';

ok 1 and done_testing;
