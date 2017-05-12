use strict;
use warnings;
use Test::Requires qw/Test::LeakTrace/;
use Data::Monad::List;
use Test::More;

no_leaks_ok {
    scalar_list(0, 1)->while(sub {
        my $v = shift;
        $v < 3;
    }, sub {
        my $v = shift;
        scalar_list($v + 1, $v + 2);
    });
};

done_testing;
