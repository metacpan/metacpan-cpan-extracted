use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Role::Float';

can_ok 'Data::Object::Role::Float', 'data';
can_ok 'Data::Object::Role::Float', 'defined';
can_ok 'Data::Object::Role::Float', 'detract';
can_ok 'Data::Object::Role::Float', 'downto';
can_ok 'Data::Object::Role::Float', 'dump';
can_ok 'Data::Object::Role::Float', 'eq';
can_ok 'Data::Object::Role::Float', 'ge';
can_ok 'Data::Object::Role::Float', 'gt';
can_ok 'Data::Object::Role::Float', 'le';
can_ok 'Data::Object::Role::Float', 'lt';
can_ok 'Data::Object::Role::Float', 'methods';
can_ok 'Data::Object::Role::Float', 'ne';
can_ok 'Data::Object::Role::Float', 'print';
can_ok 'Data::Object::Role::Float', 'roles';
can_ok 'Data::Object::Role::Float', 'say';
can_ok 'Data::Object::Role::Float', 'throw';
can_ok 'Data::Object::Role::Float', 'to';
can_ok 'Data::Object::Role::Float', 'type';
can_ok 'Data::Object::Role::Float', 'upto';

ok 1 and done_testing;
