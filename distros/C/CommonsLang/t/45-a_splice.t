use strict;
use warnings;

use CommonsLang;
use Test::More;

##
my $months = [ 'Jan', 'March', 'April', 'June' ];
is_deeply(a_splice($months, 1, 0, 'Feb'), [],                                         'a_splice.');
is_deeply($months,                        [ 'Jan', 'Feb', 'March', 'April', 'June' ], 'a_splice.');

##
my $months_2 = [ 'Jan', 'March', 'April', 'June' ];
is_deeply(a_splice($months_2, 1, 2, 'Feb'), [ 'March', 'April' ], 'a_splice.');
is_deeply($months_2, [ 'Jan', 'Feb', 'June' ], 'a_splice.');

##
my $months_3 = [ 'Jan', 'March', 'April', 'June' ];
is_deeply(a_splice($months_3, 1, 3), [ 'March', 'April', 'June' ], 'a_splice.');
is_deeply($months_3,                 ['Jan'],                      'a_splice.');

##
my $months_4 = [ 'Jan', 'March', 'April', 'June' ];
is_deeply(a_splice($months_4, 1), [ 'March', 'April', 'June' ], 'a_splice.');
is_deeply($months_4,              ['Jan'],                      'a_splice.');

##
my $months_5 = [ 'Jan', 'March', 'April', 'June' ];
is_deeply(a_splice($months_5, 1, 0, "a", "b"), [],                                            'a_splice.');
is_deeply($months_5,                           [ 'Jan', "a", "b", 'March', 'April', "June" ], 'a_splice.');

############
done_testing();
