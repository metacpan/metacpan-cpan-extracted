use warnings FATAL => 'all';
use strict;
use Test::More;

isnt($ENV{PASSED_VAR}, 'testVar', 'Not passed variable');

done_testing;