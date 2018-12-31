use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Code';

ok Data::Object::Code->does('Data::Object::Role::Defined');
ok Data::Object::Code->does('Data::Object::Role::Detract');
ok Data::Object::Code->does('Data::Object::Role::Dumper');
ok Data::Object::Code->does('Data::Object::Role::Item');
ok Data::Object::Code->does('Data::Object::Role::Throwable');
ok Data::Object::Code->does('Data::Object::Role::Type');

can_ok 'Data::Object::Code', 'call';
can_ok 'Data::Object::Code', 'compose';
can_ok 'Data::Object::Code', 'conjoin';
can_ok 'Data::Object::Code', 'curry';
can_ok 'Data::Object::Code', 'data';
can_ok 'Data::Object::Code', 'defined';
can_ok 'Data::Object::Code', 'detract';
can_ok 'Data::Object::Code', 'disjoin';
can_ok 'Data::Object::Code', 'dump';
can_ok 'Data::Object::Code', 'methods';
can_ok 'Data::Object::Code', 'new';
can_ok 'Data::Object::Code', 'next';
can_ok 'Data::Object::Code', 'rcurry';
can_ok 'Data::Object::Code', 'roles';
can_ok 'Data::Object::Code', 'throw';
can_ok 'Data::Object::Code', 'type';

ok 1 and done_testing;
