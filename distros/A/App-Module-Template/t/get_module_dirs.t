#!perl

use strict;
use warnings;

use Test::More tests => 11;

use_ok( 'App::Module::Template', '_get_module_dirs' );

ok(my $part1 = 'Some', 'set $part1');

ok(my $part2 = 'Test', 'set $part2');

ok(my $part3 = 'Name', 'set $part3');

ok(my $module_name = "$part1\:\:$part2\:\:$part3", 'set $module_name' );

ok(my $dirs = _get_module_dirs($module_name), '_get_module_dirs');

is($dirs->[0], 'lib', 'check lib is added to dirs array');

is($dirs->[1], $part1, 'second level directory');

is($dirs->[2], $part2, 'third level directory');

isnt($dirs->[3], $part3, 'last part stripped');

is($dirs->[3], undef, 'last part is undefined');
