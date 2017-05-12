
# testing class methods

use strict;
use warnings;
use Test::More;

plan tests => 4;

use Array::Unique;

is_deeply([Array::Unique->unique(qw(a s d f g))], [qw(a s d f g)], 'compare unique arrays');
is_deeply([Array::Unique->unique(qw(a s d f a))], [qw(a s d f)], 'one extra item ');
is_deeply([Array::Unique->unique(qw(a b b a))], [qw(a b)], 'two pairs');
is_deeply([Array::Unique->unique('a', 'b', undef, 'b', undef, 'a', undef)], [qw(a b)], 'undefs');



