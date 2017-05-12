use Test::More;
use strict;

use Config::Path;

my $conf = Config::Path->new(files => [ 't/conf/simple.yml', 't/conf/other.yml' ]);
ok(defined($conf));

cmp_ok($conf->fetch('a/b'), 'eq', 'c', 'depth works');
cmp_ok($conf->fetch('foo'), 'eq', 'bar', 'got foo key from file 1');
cmp_ok($conf->fetch('baz'), 'eq', 'gorch', 'got baz key from file 2');

$conf->add_file('t/conf/more.yml');

cmp_ok($conf->fetch('foo'), 'eq', 'bar', 'foo is still correct');
cmp_ok($conf->fetch('baz'), 'eq', 'gorch', 'baz is still correct');

$conf->reload;

cmp_ok($conf->fetch('foo'), 'eq', 'wozjob', 'foo covered by rightmost file (reload worked)');

cmp_ok($conf->fetch('/foo'), 'eq', 'wozjob', 'leading /');

done_testing;