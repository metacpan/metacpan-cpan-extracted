use strict;
use warnings;
use File::Which;

use Test::More;

my @utils = map {File::Which::which $_} qw /otool ldd objdump/;

ok (scalar @utils, 'have at least one of otool, ldd and objdump');
note join ' ', @utils;

done_testing();
