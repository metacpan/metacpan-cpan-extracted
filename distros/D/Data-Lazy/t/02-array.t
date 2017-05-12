#   -*- perl -*-

use strict;
use warnings;
use Test::More tests => 7;

use_ok("Data::Lazy");

{
    my @foo;
    tie @foo, 'Data::Lazy', sub { return 42*shift };
    is($foo[0], 0, "TIEARRAY interface (1)");
    is($foo[69], 2898, "TIEARRAY interface (2)");
    is (@foo, 70, "FETCHSIZE");
    $foo[70]=42;
    is (@foo, 71, "FETCHSIZE after set");
    is ($foo[70], 42, "STORE works");
}

# This example is dodgy, because variables are supposed to be untied
# inside their FETCH handlers!
{
    my @fib;
    tie @fib, 'Data::Lazy', sub {
        if ($_[0] < 0) {0}
        elsif ($_[0] == 0) {1}
        elsif ($_[0] == 1) {1}
        else {$fib[$_[0]-1]+$fib[$_[0]-2]}
    };
    # but for now, it works.
    is($fib[15], 987, "Fibbonacci generator")
}

