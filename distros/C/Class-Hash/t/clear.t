# vim: set ft=perl :

use Test::More tests => 3;
use Class::Hash;

my $hash = Class::Hash->new(apples => 1, oranges => 2, tangerines => 3, 
	{ no_named_accessors => 1, clear => 1 });

$hash->clear;
is(scalar keys %$hash, 0, 'keys');

$hash = Class::Hash->new(apples => 1, oranges => 2, tangerines => 3,
	{ no_named_accessors => 1 });

eval {
	$hash->clear;
};

if ($@) {
	pass('clear failed');
} else {
	fail('clear passed');
}

Class::Hash->clear($hash);
is(scalar keys %$hash, 0, 'keys');
