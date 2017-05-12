package Foo;

use Test::More tests => 3;

BEGIN { use_ok('Catalyst', 'Config::YAML') };

Foo->config(
	'home' => 't',
	'config_file' => [qw( ~/moose.yml config.yml config2.yml )],
);

Foo->setup;

is(Foo->config->{'blurp'}, 'moose2', 'overridden main config');
is(Foo->config->{'harry'}, 'blah', 'overridden main config');
