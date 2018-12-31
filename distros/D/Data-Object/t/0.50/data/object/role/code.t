use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Role::Code';

can_ok 'Data::Object::Role::Code', 'call';
can_ok 'Data::Object::Role::Code', 'compose';
can_ok 'Data::Object::Role::Code', 'conjoin';
can_ok 'Data::Object::Role::Code', 'curry';
can_ok 'Data::Object::Role::Code', 'data';
can_ok 'Data::Object::Role::Code', 'defined';
can_ok 'Data::Object::Role::Code', 'detract';
can_ok 'Data::Object::Role::Code', 'disjoin';
can_ok 'Data::Object::Role::Code', 'dump';
can_ok 'Data::Object::Role::Code', 'methods';
can_ok 'Data::Object::Role::Code', 'next';
can_ok 'Data::Object::Role::Code', 'rcurry';
can_ok 'Data::Object::Role::Code', 'roles';
can_ok 'Data::Object::Role::Code', 'throw';
can_ok 'Data::Object::Role::Code', 'type';

ok 1 and done_testing;
