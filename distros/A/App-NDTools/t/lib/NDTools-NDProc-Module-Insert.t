use strict;
use warnings FATAL => 'all';

use Test::More tests => 3;

use App::NDTools::NDProc::Module::Insert;

my ($exp, $got, $mod);

$mod = new_ok('App::NDTools::NDProc::Module::Insert');

$got = [0, 1, 2, 3];
$mod->process(\$got, { path => ['[]'], preserve => ['[1,0]'], value => 'test' });
$exp = [0,1,'test','test'];
is_deeply($got, $exp, "Preserve") || diag t_ab_cmp($got, $exp);

$got = [0, undef, undef, 3];
$mod->process(\$got, { path => ['[](not defined)'], preserve => ['[1]'], value => 'test' });
$exp = [0,undef,'test',3];
is_deeply($got, $exp, "Preserve, path with hooks") || diag t_ab_cmp($got, $exp);

