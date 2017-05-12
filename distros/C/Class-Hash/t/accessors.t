# vim: set ft=perl :

use Test::More tests => 6;
use Class::Hash;

my $hash = Class::Hash->new(apples => 1, oranges => 2, tangerines => 3);

$hash->apples++;
$hash->oranges = 10;
$hash->tangerines(42);

is($hash->apples, 2, 'apples');
is($hash->oranges, 10, 'oranges');
is($hash->tangerines, 42, 'tangerines');

Class::Hash->apples($hash) *= 7;
Class::Hash->oranges($hash) = 23;
Class::Hash->tangerines($hash, 19);

is(Class::Hash->apples($hash), 14, 'apples');
is(Class::Hash->oranges($hash), 23, 'oranges');
is(Class::Hash->tangerines($hash), 19, 'tangerines');
