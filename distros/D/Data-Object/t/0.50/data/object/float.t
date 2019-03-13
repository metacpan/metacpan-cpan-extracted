use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Float';

ok Data::Object::Float->does('Data::Object::Rule::Comparison');
ok Data::Object::Float->does('Data::Object::Rule::Defined');
ok Data::Object::Float->does('Data::Object::Role::Detract');
ok Data::Object::Float->does('Data::Object::Role::Dumper');
# no longer supported
# ok Data::Object::Float->does('Data::Object::Role::Numeric');
ok Data::Object::Float->does('Data::Object::Role::Output');
ok Data::Object::Float->does('Data::Object::Role::Throwable');
ok Data::Object::Float->does('Data::Object::Role::Type');
# no longer supported
# ok Data::Object::Float->does('Data::Object::Role::Value');

can_ok 'Data::Object::Float', 'data';
can_ok 'Data::Object::Float', 'defined';
can_ok 'Data::Object::Float', 'detract';
can_ok 'Data::Object::Float', 'downto';
can_ok 'Data::Object::Float', 'dump';
can_ok 'Data::Object::Float', 'eq';
can_ok 'Data::Object::Float', 'ge';
can_ok 'Data::Object::Float', 'gt';
can_ok 'Data::Object::Float', 'le';
can_ok 'Data::Object::Float', 'lt';
can_ok 'Data::Object::Float', 'methods';
can_ok 'Data::Object::Float', 'ne';
can_ok 'Data::Object::Float', 'new';
can_ok 'Data::Object::Float', 'print';
can_ok 'Data::Object::Float', 'roles';
can_ok 'Data::Object::Float', 'say';
can_ok 'Data::Object::Float', 'throw';
can_ok 'Data::Object::Float', 'to';
can_ok 'Data::Object::Float', 'type';
can_ok 'Data::Object::Float', 'upto';

ok 1 and done_testing;
