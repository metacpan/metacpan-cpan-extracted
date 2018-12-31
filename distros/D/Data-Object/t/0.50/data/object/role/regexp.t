use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Role::Regexp';

can_ok 'Data::Object::Role::Regexp', 'data';
can_ok 'Data::Object::Role::Regexp', 'defined';
can_ok 'Data::Object::Role::Regexp', 'detract';
can_ok 'Data::Object::Role::Regexp', 'dump';
can_ok 'Data::Object::Role::Regexp', 'eq';
can_ok 'Data::Object::Role::Regexp', 'ge';
can_ok 'Data::Object::Role::Regexp', 'gt';
can_ok 'Data::Object::Role::Regexp', 'le';
can_ok 'Data::Object::Role::Regexp', 'lt';
can_ok 'Data::Object::Role::Regexp', 'methods';
can_ok 'Data::Object::Role::Regexp', 'ne';
can_ok 'Data::Object::Role::Regexp', 'print';
can_ok 'Data::Object::Role::Regexp', 'replace';
can_ok 'Data::Object::Role::Regexp', 'roles';
can_ok 'Data::Object::Role::Regexp', 'say';
can_ok 'Data::Object::Role::Regexp', 'search';
can_ok 'Data::Object::Role::Regexp', 'throw';
can_ok 'Data::Object::Role::Regexp', 'type';

ok 1 and done_testing;
