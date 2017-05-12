#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use ok 'Cache::Ref::LIFO';

{
    my $c = Cache::Ref::LIFO->new( size => 3 );

    isa_ok( $c, "Cache::Ref" );

    $c->set( foo => "blah" );
    is( $c->get("foo"), "blah", "foo in cache" );

    $c->set( bar => "lala" );
    is( $c->get("foo"), "blah", "foo still in cache" );
    is( $c->get("bar"), "lala", "bar in cache" );

    $c->set( baz => "blob" );
    is( $c->get("foo"), "blah", "foo still in cache" );
    is( $c->get("bar"), "lala", "bar still in cache" );
    is( $c->get("baz"), "blob", "baz in cache" );

    $c->set( zot => "quxx" );
    is( $c->get("foo"), "blah", "foo still in cache" );
    is( $c->get("bar"), "lala", "bar still in cache" );
    is( $c->get("baz"), "blob", "baz still in cache" );
    is( $c->get("zot"), undef, "zot in not in cache" );

    $c->set( baz => "jsd" );
    $c->set( quxx => "dancing" );
    is( $c->get("foo"), "blah", "foo still in cache" );
    is( $c->get("bar"), "lala", "bar still in cache" );
    is( $c->get("baz"), "jsd", "baz still in cache" );
    is( $c->get("zot"), undef, "zot in not in cache" );
    is( $c->get("quxx"), undef, "quxx not in cache" );

    $c->remove("quxx");

    is( $c->get("foo"), "blah", "foo still in cache" );
    is( $c->get("bar"), "lala", "bar still in cache" );
    is( $c->get("baz"), "jsd", "baz still in cache" );
    is( $c->get("zot"), undef, "zot in not in cache" );
    is( $c->get("quxx"), undef, "quxx not in cache" );

    $c->remove("foo");

    is( $c->get("foo"), undef, "foo no longer in cache" );
    is( $c->get("bar"), "lala", "bar still in cache" );
    is( $c->get("baz"), "jsd", "baz still in cache" );
    is( $c->get("zot"), undef, "zot in not in cache" );
    is( $c->get("quxx"), undef, "quxx not in cache" );

    $c->set( quxx => "dancing" );

    is( $c->get("foo"), undef, "foo no longer in cache" );
    is( $c->get("bar"), "lala", "bar still in cache" );
    is( $c->get("baz"), "jsd", "baz still in cache" );
    is( $c->get("zot"), undef, "zot in not in cache" );
    is( $c->get("quxx"), "dancing", "quxx in cache" );

    is_deeply( [ $c->get(qw(bar baz nothere)) ], [ qw(lala jsd), undef ], "mget" );

    is( $c->_index_size, 3, "refilled" );

    $c->expire(2);

    is( $c->_index_size, 1, "expired" );

    $c->clear;

    is( $c->_index_size, 0, "no elements in cache" );
}

{
    my $c = Cache::Ref::LIFO->new( size => 5 );

    my ( $hit, $miss ) = ( 0, 0 );

    for ( 1 .. 2000 ) {
        my $key = 1 + int rand 8;

        if ( $c->get($key) ) {
            $hit++;
        } else {
            $miss++;
            $c->set($key => $key);
        }
    }

    cmp_ok( $hit, '>=', $miss, "more cache hits than misses during random access of small sigma ($hit >= $miss)" );

    ( $hit, $miss ) = ( 0, 0 );

    for ( 1 .. 100 ) {
        foreach my $key ( 1 .. 10 ) {
            if ( $c->get($key) ) {
                $hit++;
            } else {
                $miss++;
                $c->set($key => $key);
            }
        }
    }

    cmp_ok( $hit, '==', $miss, "hit rate during linear scan ($hit == $miss)" );
}


done_testing;

# ex: set sw=4 et:

