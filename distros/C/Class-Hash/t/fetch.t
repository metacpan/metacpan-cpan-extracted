# vim: set ft=perl :

use Test::More tests => 7;
use Class::Hash;

my $hash = Class::Hash->new(apples => 1, oranges => 2, tangerines => 3, 
	{ no_named_accessors => 1, fetch => 1 });

is($hash->fetch('apples'), 1, 'apples');
is($hash->fetch('oranges'), 2, 'oranges');
is($hash->fetch('tangerines'), 3, 'tangerines');

Class::Hash->options($hash)->{fetch} = 0;

eval {
	my $apples = $hash->fetch('apples');
};

if ($@) {
	pass('fetch failed');
} else {
	fail('fetch succeeded');
}

is(Class::Hash->fetch($hash, 'apples'), 1, 'apples');
is(Class::Hash->fetch($hash, 'oranges'), 2, 'oranges');
is(Class::Hash->fetch($hash, 'tangerines'), 3, 'tangerines');
