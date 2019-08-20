# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use TestConfig;

plan(tests => 3);

my $cfg = new TestConfig(
    config => [
	'core.retain-interval' => 10,
	'core.tempdir' => '/tmp'
    ]
    );
ok(join(',', sort $cfg->getnode('core')->keys), 'retain-interval,tempdir');
ok($cfg->getnode('core')->keys, 2);
ok(join(',', sort $cfg->names_of('core')), 'retain-interval,tempdir');
