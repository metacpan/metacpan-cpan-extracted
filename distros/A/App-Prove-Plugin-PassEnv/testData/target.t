use warnings FATAL => 'all';
use strict;
use Test::More;

is($ENV{PASSED_VAR}, 'testVar');

done_testing;