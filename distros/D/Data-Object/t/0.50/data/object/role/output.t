use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Role::Output';


can_ok 'Data::Object::Role::Output', 'print';
can_ok 'Data::Object::Role::Output', 'say';

ok 1 and done_testing;
