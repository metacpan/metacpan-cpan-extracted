use strict;
use warnings;
use Test::More;
use Data::Monad::Base::Util qw(list);

sub a_function($$$) {
    my ($x, $y, $z) = @_;
    my @results = ($x + 10, $y + 100, $z + 1000);
    return list @results;
}

is_deeply [a_function 3, 2, 1], [13, 102, 1001];
is_deeply scalar(a_function 3, 2, 1), 13;

done_testing;
