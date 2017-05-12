package SomeComponent;

@ISA = qw(Catalyst::Base);

package Foo;

use Test::More tests => 3;

BEGIN { use_ok('Catalyst', 'Config::JSON') };

Foo->config(
	'home' => 't', 
);

Foo->setup;

is(Foo->config->{'blurp'}, 'moose', 'main config');

is(SomeComponent->config->{'Hello'}, 'There', 'component config');
