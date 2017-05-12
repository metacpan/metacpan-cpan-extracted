#   -*- perl -*-

use strict;
use warnings;
use Test::More tests => 5;

use_ok("Data::Lazy");

{
    my %foo;
    tie %foo, 'Data::Lazy', sub { reverse shift };
    is($foo{hello}, "olleh", "TIEHASH interface (1)");
    is($foo{''}, '', "TIEHASH interface (2)");
    is($foo{'hmm'}, 'mmh', "TIEHASH interface (3)");
    $foo{bar} = "baz";
    is ($foo{bar}, "baz", "STORE works");
}

