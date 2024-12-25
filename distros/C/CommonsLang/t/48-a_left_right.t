use strict;
use warnings;

use CommonsLang;
use Test::More;

##
is_deeply(a_left([ "a", "b", "c" ], 0), [],                'a_left.');
is_deeply(a_left([ "a", "b", "c" ], 1), ["a"],             'a_left.');
is_deeply(a_left([ "a", "b", "c" ], 2), [ "a", "b" ],      'a_left.');
is_deeply(a_left([ "a", "b", "c" ], 3), [ "a", "b", "c" ], 'a_left.');
is_deeply(a_left([ "a", "b", "c" ], 4), [ "a", "b", "c" ], 'a_left.');

##
is_deeply(a_right([ "a", "b", "c" ], 0), [],                'a_right.');
is_deeply(a_right([ "a", "b", "c" ], 1), ["c"],             'a_right.');
is_deeply(a_right([ "a", "b", "c" ], 2), [ "b", "c" ],      'a_right.');
is_deeply(a_right([ "a", "b", "c" ], 3), [ "a", "b", "c" ], 'a_right.');
is_deeply(a_right([ "a", "b", "c" ], 4), [ "a", "b", "c" ], 'a_right.');


############
done_testing();
