# vim: set ft=perl :

use Test::More tests => 7;
use Class::Hash;

my $hash = Class::Hash->new(apples => 1, oranges => 2, tangerines => 3, 
	{ no_named_accessors => 1, store => 1 });

$hash->store('apples', 3);
$hash->store('oranges') = 5;
Class::Hash->store($hash, 'tangerines', 7);
Class::Hash->store($hash, 'peaches') = 9;

is($hash->{apples}, 3, 'apples');
is($hash->{oranges}, 5, 'oranges');
is($hash->{tangerines}, 7, 'tangerines');
is($hash->{peaches}, 9, 'peaches');

Class::Hash->options($hash)->{store} = 0;

eval {
	my $apples = $hash->store('apples') = 17;
};

if ($@) {
	pass('fetch failed');
} else {
	fail('fetch succeeded');
}

Class::Hash->store($hash, 'oranges', 10);
Class::Hash->store($hash, 'tangerines') = 14;

is($hash->{oranges}, 10, 'oranges');
is($hash->{tangerines}, 14, 'tangerines');
