use Test::More;
use strict;

use Config::Path;

my $conf = Config::Path->new(directory => 't/conf' );
ok(defined($conf));

cmp_ok($conf->fetch('a/b'), 'eq', 'c', 'depth works');
cmp_ok($conf->fetch('foo'), 'eq', 'bar', 'got foo key from file 1');
cmp_ok($conf->fetch('baz'), 'eq', 'gorch', 'got baz key from file 2');
cmp_ok($conf->fetch('foo'), 'eq', 'bar', 'foo covered by rightmost file (sort worked)');

done_testing;