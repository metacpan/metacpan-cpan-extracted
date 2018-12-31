use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Role::Type';


can_ok 'Data::Object::Role::Type', 'methods';
can_ok 'Data::Object::Role::Type', 'roles';
can_ok 'Data::Object::Role::Type', 'type';

ok 1 and done_testing;
