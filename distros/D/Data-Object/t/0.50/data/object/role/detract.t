use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Role::Detract';


can_ok 'Data::Object::Role::Detract', 'data';
can_ok 'Data::Object::Role::Detract', 'detract';

ok 1 and done_testing;
