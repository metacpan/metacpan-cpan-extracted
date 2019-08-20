# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use TestConfig;

plan(tests => 7);

my $cfg = new TestConfig(
    config => [
	'core.retain-interval' => '10',
	'core.tempdir' => '/tmp',
	'backend.foo.file' => 'foo'
    ]
);

ok($cfg->is_set('backend','foo','file'));
ok($cfg->is_variable('backend','foo','file'));
ok($cfg->get('backend','foo','file'), 'foo');

ok($cfg->is_set('core', 'verbose') == 0);

ok($cfg->is_section('backend','foo'));

$cfg->set('core','verbose','On');
ok($cfg->get('core','verbose'),'On');

$cfg->unset('core','tmpdir');
ok($cfg->is_set('core','tmpdir') == 0);

