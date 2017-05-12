# vim: set ft=perl :

use Test::More tests => 2;
use Class::Hash;

$hash = Class::Hash->new({ METHOD_BASED => 1 });

is_deeply(Class::Hash->options($hash), {
		no_named_accessors => 1,
		fetch => 1,
		store => 1,
		delete => 1,
		clear => 1,
		exists => 1,
		each => 1,
		keys => 1,
		values => 1,
	}, 'METHOD_BASED options');

$hash = Class::Hash->new({ ALL_METHODS => 1 });

is_deeply(Class::Hash->options($hash), {
		fetch => 1,
		store => 1,
		delete => 1,
		clear => 1,
		exists => 1,
		each => 1,
		keys => 1,
		values => 1,
	}, 'ALL_METHODS options');
