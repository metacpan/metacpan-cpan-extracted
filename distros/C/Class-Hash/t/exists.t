# vim: set ft=perl :

use Test::More tests => 5;
use Class::Hash;

my $hash = Class::Hash->new(apples => 1, oranges => 2, tangerines => 3, 
	{ no_named_accessors => 1, 'exists' => 1 });

ok($hash->exists('apples'), 'apples');
ok(!$hash->exists('peaches'), 'peaches');

Class::Hash->options($hash)->{'exists'} = 0;

eval {
	$hash->exists('apples');
};

if ($@) {
	pass('exists failed');
} else {
	fail('exists succeeded');
}

ok(Class::Hash->exists($hash, 'apples'), 'apples');
ok(!Class::Hash->exists($hash, 'peaches'), 'peaches');
