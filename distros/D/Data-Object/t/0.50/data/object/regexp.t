use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Regexp';

ok Data::Object::Regexp->does('Data::Object::Role::Alphabetic');
ok Data::Object::Regexp->does('Data::Object::Role::Comparison');
ok Data::Object::Regexp->does('Data::Object::Role::Defined');
ok Data::Object::Regexp->does('Data::Object::Role::Detract');
ok Data::Object::Regexp->does('Data::Object::Role::Dumper');
ok Data::Object::Regexp->does('Data::Object::Role::Item');
ok Data::Object::Regexp->does('Data::Object::Role::Output');
ok Data::Object::Regexp->does('Data::Object::Role::Throwable');
ok Data::Object::Regexp->does('Data::Object::Role::Type');
ok Data::Object::Regexp->does('Data::Object::Role::Value');

can_ok 'Data::Object::Regexp', 'data';
can_ok 'Data::Object::Regexp', 'defined';
can_ok 'Data::Object::Regexp', 'detract';
can_ok 'Data::Object::Regexp', 'dump';
can_ok 'Data::Object::Regexp', 'eq';
can_ok 'Data::Object::Regexp', 'ge';
can_ok 'Data::Object::Regexp', 'gt';
can_ok 'Data::Object::Regexp', 'le';
can_ok 'Data::Object::Regexp', 'lt';
can_ok 'Data::Object::Regexp', 'methods';
can_ok 'Data::Object::Regexp', 'ne';
can_ok 'Data::Object::Regexp', 'new';
can_ok 'Data::Object::Regexp', 'print';
can_ok 'Data::Object::Regexp', 'replace';
can_ok 'Data::Object::Regexp', 'roles';
can_ok 'Data::Object::Regexp', 'say';
can_ok 'Data::Object::Regexp', 'search';
can_ok 'Data::Object::Regexp', 'throw';
can_ok 'Data::Object::Regexp', 'type';

ok 1 and done_testing;
