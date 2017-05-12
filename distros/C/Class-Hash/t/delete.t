# vim: set ft=perl :

use Test::More tests => 4;
use Class::Hash;

my $hash = Class::Hash->new(apples => 1, oranges => 2, tangerines => 3, 
	{ no_named_accessors => 1, 'delete' => 1 });

$hash->delete('apples');
Class::Hash->delete($hash, 'oranges');

ok(!exists $hash->{apples}, 'apples');
ok(!exists $hash->{oranges}, 'oranges');

Class::Hash->options($hash)->{'delete'} = 0;

eval {
	$hash->delete('tangerines');
};

ok(exists $hash->{tangerines}, 'tangerines');

Class::Hash->delete($hash, 'tangerines');

ok(!exists $hash->{tangerines}, 'tangerines');
