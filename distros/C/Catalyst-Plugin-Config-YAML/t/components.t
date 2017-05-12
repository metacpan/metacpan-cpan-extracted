package Foo;

use Test::More tests => 2;

use lib 't';

BEGIN { use_ok('Catalyst', 'Config::YAML') };

Foo->config(
	'home' => 't', 
);

Foo->setup;

is(Foo::C::Bar->config->{'soothe'}, 'bedazzled', 'main config');
