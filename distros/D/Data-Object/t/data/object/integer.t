use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Integer';

ok Data::Object::Integer->does('Data::Object::Role::Comparison');
ok Data::Object::Integer->does('Data::Object::Role::Defined');
ok Data::Object::Integer->does('Data::Object::Role::Detract');
ok Data::Object::Integer->does('Data::Object::Role::Dumper');
ok Data::Object::Integer->does('Data::Object::Role::Item');
ok Data::Object::Integer->does('Data::Object::Role::Numeric');
ok Data::Object::Integer->does('Data::Object::Role::Output');
ok Data::Object::Integer->does('Data::Object::Role::Throwable');
ok Data::Object::Integer->does('Data::Object::Role::Type');
ok Data::Object::Integer->does('Data::Object::Role::Value');

can_ok 'Data::Object::Integer', 'data';
can_ok 'Data::Object::Integer', 'defined';
can_ok 'Data::Object::Integer', 'detract';
can_ok 'Data::Object::Integer', 'downto';
can_ok 'Data::Object::Integer', 'dump';
can_ok 'Data::Object::Integer', 'eq';
can_ok 'Data::Object::Integer', 'ge';
can_ok 'Data::Object::Integer', 'gt';
can_ok 'Data::Object::Integer', 'le';
can_ok 'Data::Object::Integer', 'lt';
can_ok 'Data::Object::Integer', 'methods';
can_ok 'Data::Object::Integer', 'ne';
can_ok 'Data::Object::Integer', 'new';
can_ok 'Data::Object::Integer', 'print';
can_ok 'Data::Object::Integer', 'roles';
can_ok 'Data::Object::Integer', 'say';
can_ok 'Data::Object::Integer', 'throw';
can_ok 'Data::Object::Integer', 'to';
can_ok 'Data::Object::Integer', 'type';
can_ok 'Data::Object::Integer', 'upto';

ok 1 and done_testing;
