#!perl

use strict;
use warnings;

use Test::More 0.88 tests => 4;
use File::Compare;

use App::PrereqGrapher;
my $grapher;

$grapher = App::PrereqGrapher->new(format => 'dot', output_file => 'example1.dot');
$grapher->generate_graph('Module::Path');
ok(compare('example1.dot', 'module-path.dot'), 'Check graph for Module::Path');
chmod(0600, 'example1.dot');
ok(unlink('example1.dot'), "remove graph after running test");

$grapher = App::PrereqGrapher->new(depth => 2, format => 'dot', output_file => 'example2.dot');
$grapher->generate_graph('Module::Path');
ok(compare('example2.dot', 'module-path-depth-2.dot'), 'Check graph for Module::Path to depth 2');
chmod(0600, 'example2.dot');
ok(unlink('example2.dot'), "remove graph after running test");

