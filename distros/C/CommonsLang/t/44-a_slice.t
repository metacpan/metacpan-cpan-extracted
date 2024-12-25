use strict;
use warnings;

use CommonsLang;
use Test::More;

##
my $fruits_1 = [ "Banana", "Orange", "Lemon", "Apple", "Mango" ];
is_deeply(
    a_slice($fruits_1, 1, 3),
    [ "Orange", "Lemon" ],
    'a_slice.'
);

############
done_testing();
