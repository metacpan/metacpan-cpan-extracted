# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use TestConfig;

plan(tests => 6);

my $t = new TestConfig(
    config => [
        base => 8,
	offset => 10,
	type => 'file'
    ]);

ok($t->getnode('base') < $t->getnode('offset'));
ok($t->getnode('base') + 3, 11);
ok($t->getnode('unref') || $t->getnode('base'), 8);
ok($t->getnode('offset') || $t->getnode('base'), 10);
ok($t->getnode('type') cmp 'find', -1);
ok($t->getnode('base') . $t->getnode('type'), '8file')