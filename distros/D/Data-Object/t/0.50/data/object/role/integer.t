use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Role::Integer';

can_ok 'Data::Object::Role::Integer', 'data';
can_ok 'Data::Object::Role::Integer', 'defined';
can_ok 'Data::Object::Role::Integer', 'detract';
can_ok 'Data::Object::Role::Integer', 'downto';
can_ok 'Data::Object::Role::Integer', 'dump';
can_ok 'Data::Object::Role::Integer', 'eq';
can_ok 'Data::Object::Role::Integer', 'ge';
can_ok 'Data::Object::Role::Integer', 'gt';
can_ok 'Data::Object::Role::Integer', 'le';
can_ok 'Data::Object::Role::Integer', 'lt';
can_ok 'Data::Object::Role::Integer', 'methods';
can_ok 'Data::Object::Role::Integer', 'ne';
can_ok 'Data::Object::Role::Integer', 'print';
can_ok 'Data::Object::Role::Integer', 'roles';
can_ok 'Data::Object::Role::Integer', 'say';
can_ok 'Data::Object::Role::Integer', 'throw';
can_ok 'Data::Object::Role::Integer', 'to';
can_ok 'Data::Object::Role::Integer', 'type';
can_ok 'Data::Object::Role::Integer', 'upto';

ok 1 and done_testing;
