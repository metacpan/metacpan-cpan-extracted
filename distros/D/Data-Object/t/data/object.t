use strict;
use warnings;
use Test::More;

use_ok 'Data::Object';

can_ok 'Data::Object', 'codify';
can_ok 'Data::Object', 'const';
can_ok 'Data::Object', 'data_array';
can_ok 'Data::Object', 'data_code';
can_ok 'Data::Object', 'data_float';
can_ok 'Data::Object', 'data_hash';
can_ok 'Data::Object', 'data_integer';
can_ok 'Data::Object', 'data_number';
can_ok 'Data::Object', 'data_regexp';
can_ok 'Data::Object', 'data_scalar';
can_ok 'Data::Object', 'data_string';
can_ok 'Data::Object', 'data_undef';
can_ok 'Data::Object', 'data_universal';
can_ok 'Data::Object', 'deduce';
can_ok 'Data::Object', 'deduce_deep';
can_ok 'Data::Object', 'deduce_type';
can_ok 'Data::Object', 'detract';
can_ok 'Data::Object', 'detract_deep';
can_ok 'Data::Object', 'immutable';
can_ok 'Data::Object', 'load';
can_ok 'Data::Object', 'new';
can_ok 'Data::Object', 'prototype';
can_ok 'Data::Object', 'throw';

ok 1 and done_testing;
