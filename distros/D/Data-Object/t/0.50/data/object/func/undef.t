use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Func::Undef';
use_ok 'Data::Object::Func::Undef::Defined';
use_ok 'Data::Object::Func::Undef::Eq';
use_ok 'Data::Object::Func::Undef::Gt';
use_ok 'Data::Object::Func::Undef::Ge';
use_ok 'Data::Object::Func::Undef::Lt';
use_ok 'Data::Object::Func::Undef::Le';
use_ok 'Data::Object::Func::Undef::Ne';

ok 1 and done_testing;
