#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Moose;

#foreach my $impl qw(Cache::Ref::Util::LRU::Array Cache::Ref::Util::LRU::List) {
foreach my $impl (qw(Cache::Ref::Util::LRU::List)) {
    use_ok($impl);

    isa_ok( my $l = $impl->new, $impl );

    does_ok( $l, "Cache::Ref::Util::LRU::API" );

    is( $l->lru, undef, "no mru" );
    is( $l->mru, undef, "no lru" );

    my ( $foo, $bar ) = $l->insert(qw(foo bar));

    is( $l->mru, "foo", "get mru" );
    is( $l->lru, "bar", "get lru" );

    $l->hit($bar);

    is( $l->mru, "bar", "get mru" );
    is( $l->lru, "foo", "get lru" );

    my $baz = $l->insert("baz");

    is( $l->mru, "baz", "get mru" );
    is( $l->lru, "foo", "get lru" );

    $l->hit($bar);

    is( $l->mru, "bar", "get mru" );
    is( $l->lru, "foo", "get lru" );

    $l->hit($foo);

    is( $l->mru, "foo", "get mru" );
    is( $l->lru, "baz", "get lru" );

    is( $l->remove_lru, "baz", "remove lru" );
    is( $l->remove_lru, "bar", "remove lru" );
    is( $l->remove_lru, "foo", "remove lru" );
    is( $l->remove_lru, undef, "remove lru" );

    foreach my $remove ( qw(remove_lru remove_mru) ) {
        $l->insert("foo");
        is( $l->lru, "foo", "lru" );
        is( $l->mru, "foo", "mru" );
        is( $l->$remove, "foo", "remove" );
        is( $l->remove_lru, undef, "nothing to remove" );
        is( $l->remove_mru, undef, "nothing to remove" );
    }

    $foo = $l->insert("foo");
    $bar = $l->insert("bar");
    $baz = $l->insert("baz");

    $l->hit($baz);

    is( $l->mru, "baz", "get mru" );
    is( $l->lru, "foo", "get lru" );

    $l->hit($bar);

    is( $l->mru, "bar", "get mru" );
    is( $l->lru, "foo", "get lru" );

    $l->hit($foo);

    is( $l->mru, "foo", "get mru" );
    is( $l->lru, "baz", "get lru" );

    $l->hit($baz);

    is( $l->mru, "baz", "get mru" );
    is( $l->lru, "bar", "get lru" );

    $l->hit($foo, $bar);

    is( $l->mru, "foo", "get mru" );
    is( $l->lru, "baz", "get lru" );

    $l->hit($bar, $baz);

    is( $l->mru, "bar", "get mru" );
    is( $l->lru, "foo", "get lru" );

    $l->hit($baz, $foo, $bar);

    is( $l->remove_lru, "bar", "remove lru" );

    is( $l->lru, "foo", "get lru" );

    $l->hit($foo);

    is( $l->mru, "foo", "get mru" );
    is( $l->lru, "baz", "get lru" );

    is( $l->remove_mru, "foo", "remove mru" );

    is( $l->mru, "baz", "get mru" );
    is( $l->lru, "baz", "get lru" );

    is( $l->remove_mru, "baz" );

    is( $l->lru, undef, "no lru" );
    is( $l->mru, undef, "no mru" );

    ( $foo, $bar, $baz ) = $l->insert(qw(foo bar baz));

    $l->remove($bar);

    is( $l->mru, "foo", "get mru" );
    is( $l->lru, "baz", "get lru" );

    $l->remove($foo);

    is( $l->mru, "baz", "get lru" );
    is( $l->lru, "baz", "get lru" );

    $l->remove($baz);

    is( $l->lru, undef, "no lru" );
    is( $l->mru, undef, "no mru" );

    $l->insert(qw(foo bar));

    $l->hit;
    $l->insert;

    is( $l->mru, "foo", "get mru" );
    is( $l->lru, "bar", "get lru" );

    $l->clear;

    is( $l->lru, undef, "no lru" );
    is( $l->mru, undef, "no mru" );

    $l->clear;

    is( $l->lru, undef, "no lru" );
    is( $l->mru, undef, "no mru" );
}

done_testing;

# ex: set sw=4 et:

