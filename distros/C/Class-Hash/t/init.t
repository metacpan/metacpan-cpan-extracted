# vim: set ft=perl :

use Test::More tests => 6;
use Class::Hash;

my $hash = Class::Hash->new(apples => 1, oranges => 2, tangerines => 3);

is($hash->apples, 1, 'apples');
is($hash->oranges, 2, 'oranges');
is($hash->tangerines, 3, 'tangerines');

is($hash->{apples}, 1, 'regular apples');
is($hash->{oranges}, 2, 'regular oranges');
is($hash->{tangerines}, 3, 'regular tangerines');
