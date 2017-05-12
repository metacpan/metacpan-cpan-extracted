use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Role::Numeric';


can_ok 'Data::Object::Role::Numeric', 'downto';
can_ok 'Data::Object::Role::Numeric', 'eq';
can_ok 'Data::Object::Role::Numeric', 'ge';
can_ok 'Data::Object::Role::Numeric', 'gt';
can_ok 'Data::Object::Role::Numeric', 'le';
can_ok 'Data::Object::Role::Numeric', 'lt';
can_ok 'Data::Object::Role::Numeric', 'ne';
can_ok 'Data::Object::Role::Numeric', 'to';
can_ok 'Data::Object::Role::Numeric', 'upto';

ok 1 and done_testing;
