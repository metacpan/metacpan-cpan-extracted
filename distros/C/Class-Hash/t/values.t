# vim: set ft=perl :

use Test::More tests => 4;
use Class::Hash;

my $hash = Class::Hash->new(apples => 1, oranges => 2, tangerines => 3, 
	{ no_named_accessors => 1, 'values' => 1 });

my $fruit = [ 1, 2, 3 ];
	
is_deeply([ sort($hash->values) ], $fruit, '');
is_deeply([ sort(Class::Hash->values($hash)) ], $fruit, 'values');

Class::Hash->options($hash)->{'values'} = 0;

eval {
	$hash->values;
};

if ($@) {
	pass('values failed');
} else {
	fail('valuews succeeded');
}

is_deeply([ sort(Class::Hash->values($hash)) ], $fruit, 'values');
