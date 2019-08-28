# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use TestConfig;

plan(tests => 1);

my $cfg = new TestConfig(
    config => [
	'core.retain-interval' => '10',
	'core.tempdir' => '/tmp',
	'backend.foo.file' => 'a'
    ]
);
ok($cfg->canonical, 'backend.foo.file="a" core.retain-interval=10 core.tempdir="/tmp"');
    
