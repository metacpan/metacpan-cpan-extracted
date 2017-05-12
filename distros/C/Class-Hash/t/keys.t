# vim: set ft=perl :

use Test::More tests => 4;
use Class::Hash;

my $hash = Class::Hash->new(apples => 1, oranges => 2, tangerines => 3, 
	{ no_named_accessors => 1, 'keys' => 1 });

my $fruit = [ qw( apples oranges tangerines ) ];
	
is_deeply([ sort($hash->keys) ], $fruit, 'keys');
is_deeply([ sort(Class::Hash->keys($hash)) ], $fruit, 'keys');

Class::Hash->options($hash)->{'keys'} = 0;

eval {
	$hash->keys;
};

if ($@) {
	pass('keys failed');
} else {
	fail('keys succeeded');
}

is_deeply([ sort(Class::Hash->keys($hash)) ], $fruit, 'keys');
