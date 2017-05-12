#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 14;

BEGIN {
    use_ok( 'Acme::Hyperindex' );
}

{ ### Scalar data
    my $data = [
        {
            foo => [qw(a b c)],
            baz => [qw(d e f)],
        },
        {
            foo => [qw(g h i)],
            baz => [qw(j k l)],
        },
    ];

    is $data[[ 0, 'foo', 2 ]], 'c',         "Works with list as indexer";
    is $data[[ @{[ 1, 'baz', 0 ]} ]], 'j',  "Also with array as indexer";

    sub get_index { return qw(0 baz 1) }
    is $data[[ get_index() ]], 'e',         "And parses also if we use a sub";

    my $indexer = { reutel => [qw(1 foo 0)] };
    is $data[[ $indexer[[ 'reutel' ]] ]], 'g', "Even parses a hyperindex as indexer";

    is $data[[ qw[ 0 baz 2] ]], 'f',        "Parse qw[ ... ]";
}

{ ### Array data
    my @data = (
        [qw(a b c)],
        [qw(d e f)],
    );

    is @data[[0,1]], 'b', "Array: list indexer";
    is @data[[ @{[ 1,0 ]} ]], 'd', "Array: array indexer";

    sub get_index2 { return 0, 2 };
    is @data[[ get_index2() ]], 'c', "Array: sub indexer";

    my @indexer = ({ reutel => [ 1, 2 ] });
    is @data[[ @indexer[[ qw( 0 reutel ) ]] ]], 'f', "Array: hyperindex result as indexer";
}

{ ### Hash data
    my %data = (
        foo => { zot => 'a' },
        bar => { zot => 'b' },
        bas => { zot => 'c' },
    );

    is %data[[ qw(foo zot) ]], 'a', "Hash: list indexer";
    is %data[[ @{[qw(bar zot)]} ]], 'b', "Hash: array indexer";

    sub get_index3 { return qw( bas zot ) }
    is %data[[ get_index3() ]], 'c', "Hash: sub indexer";

    my %indexer = (
        reutel => [
            [qw(foo zot)],
            [qw(bar zot)],
            [qw(bas zot)],
        ],
    );
    is %data[[ %indexer[[ qw(reutel 1) ]] ]], 'b', "Hash: hyperindexer result as indexer";
}






