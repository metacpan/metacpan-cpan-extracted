use strict;
use warnings;

use CommonsLang;
use Test::More;

##
my $fruits_1 = [ "Banana", "Orange", "Lemon", "Apple", "Mango" ];
is_deeply(a_sort($fruits_1), [ "Apple", "Banana", "Lemon", "Mango", "Orange" ], 'a_sort.');

##
my $fruits_2 = [ "Banana", "Orange", "Lemon", "Apple", "Mango" ];
my $order_2  = [ "Orange", "Banana", "Lemon", "Apple", "Mango" ];
is_deeply(
    a_sort(
        $fruits_2,
        sub {
            my ($x, $y) = @_;
            my $x_odr = a_index_of($order_2, $x);
            my $y_odr = a_index_of($order_2, $y);
            return $x_odr <=> $y_odr;
        }
    ),
    [ "Orange", "Banana", "Lemon", "Apple", "Mango" ],
    'a_sort.'
);

############
done_testing();
