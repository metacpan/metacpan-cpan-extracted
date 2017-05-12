#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;

BEGIN {
    use_ok 'Acme::Hyperindex';
}

ok( Acme::Hyperindex->can( 'hyperindex' ), "We can hyperindex" );

{
    my $structure = [
        [
            [qw(a b c)],
            [qw(d e f)],
        ],
        [
            [qw(g h i)],
            [qw(j k l)],
        ],
    ];
    my @index = (1, 0, 2);

    is( hyperindex( $structure, 1, 0, 2 ), 'i', "Works in scalar context" );
    is( (hyperindex( $structure, @{[0, 0, 2]} ))[0], 'c', "Works in list context" );

    is_deeply(
        scalar hyperindex( $structure, @{[0,1]} ),
        [qw(d e f)],
        "Return structure ref in scalar context"
    );

    is_deeply(
        [ hyperindex( $structure, 1, 1 ) ],
        [qw(j k l)],
        "Return dereferenced structure in list context",
    );
}

{
    my $structure = [[
        {
            foo => [qw(a b c)],
            bar => [qw(d e f)],
        },
        {
            foo => [qw(g h i)],
            bar => [qw(j k l)],
        },
    ]];

    my @index = qw(0 0 foo 0);
    is( hyperindex( $structure, @index ), 'a', "Handles hashref" );

    is_deeply(
        [hyperindex( $structure, 0, 0, 'bar' )],
        [qw(d e f)],
        "Returns dereferenced structures in list context",
    );
    is_deeply(
        {hyperindex( $structure, 0, 1 )},
        { foo => [qw(g h i)], bar => [qw(j k l)] },
        "Returns dereferenced hash in list context",
    );

    is_deeply(
        scalar hyperindex( $structure, 0, 0 ),
        { foo => [qw(a b c)], bar => [qw(d e f)] },
        "Returns reference in scalar context",
    );

    is_deeply(
        scalar hyperindex( $structure, qw( 0 1 bar 1 ) ),
        'k',
        "Returns item in scalar context when item is no ref"
    );
}





