use Test::More;
use strict;

use Config::Path;

my $conf = Config::Path->new(files => [ 't/conf/simple.yml', 't/conf/other.yml' ]);
ok(defined($conf));

cmp_ok($conf->fetch('a/b'), 'eq', 'c', 'depth works');
cmp_ok($conf->fetch('foo'), 'eq', 'bar', 'got foo key from file 1');

$conf->mask('a/b', 'd');
$conf->mask('foo', 'baz');

cmp_ok($conf->fetch('a/b'), 'eq', 'd', 'mask path a/b');
cmp_ok($conf->fetch('foo'), 'eq', 'baz', 'mask path foo');

$conf->reload;

cmp_ok($conf->fetch('a/b'), 'eq', 'c', 'mask path a/b reload');
cmp_ok($conf->fetch('foo'), 'eq', 'bar', 'mask path foo reload');

done_testing;