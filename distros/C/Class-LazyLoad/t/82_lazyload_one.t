use strict;

use lib 't/lib';

use Test::More tests => 2;

my ($CLASS, $TEST);
BEGIN {
    $CLASS = 'Class::LazyLoad';

    use_ok( $CLASS . '::Functions', qw( lazyload_one ) );
}

eval {
    my $lazy = lazyload_one();
};
is( $@, "Must pass in (CLASS, [ CONSTRUCTOR, [ARGS] ]) to lazyload_one().\n",
    "lazyload_one() correctly fails"
);
