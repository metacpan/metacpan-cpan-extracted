#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use ok 'Cache::Ref::CLOCK';
use ok 'Cache::Ref::GCLOCK';

foreach my $impl (qw(Cache::Ref::CLOCK Cache::Ref::GCLOCK)) {
    {
        my $c = $impl->new( size => 3 );

        isa_ok( $c, "Cache::Ref" );

        $c->set( foo => "blah" );
        is( $c->get("foo"), "blah", "foo" );

        $c->set( bar => "lala" );
        is( $c->get("bar"), "lala", "bar" );

        $c->set( baz => "blob" );
        is( $c->get("baz"), "blob", "baz" );

        $c->set( zot => "quxx" );
        is( $c->get("zot"), "quxx", "zot" );

        is( $c->get("bar"), "lala", "bar still in cache" );

        is( $c->get("foo"), undef, "foo no longer in cache" );

        $c->set( quxx => "tmp" );
        $c->set( quxx => "dancing" );

        is( $c->get("bar"), "lala", "bar still in cache" );
        is( $c->get("baz"), undef, "baz no longer in cache" );
        is( $c->get("zot"), "quxx", "zot still in cache" );
        is( $c->get("quxx"), "dancing", "quxx in cache" );

        $c->remove("quxx");

        is( $c->get("bar"), "lala", "bar still in cache" );
        is( $c->get("baz"), undef, "baz no longer in cache" );
        is( $c->get("zot"), "quxx", "zot still in cache" );
        is( $c->get("quxx"), undef, "quxx removed from cache" );

        is( $c->_index_size, 2, "two elements in cache" );

        $c->set( quxx => "blah" );

        is( $c->get("bar"), "lala", "bar still in cache" );
        is( $c->get("baz"), undef, "baz no longer in cache" );
        is( $c->get("zot"), "quxx", "zot still in cache" );
        is( $c->get("quxx"), "blah", "quxx in cache" );

        if ( $c->isa("Cache::Ref::CLOCK") ) {
            $c->set( new => "element" ); # overwrites 'zot' due to current value of _hand
            $c->hit("bar");
            $c->set( another => "member" );
        } else {
            $c->hit("bar") for 1 .. 3;
            $c->set("new" => "element"); # expires 'quxx'
            $c->hit("new"); # otherwise it's less frequently used than 'zot'
            $c->set("another" => "member");
        }

        is( $c->get("bar"), "lala", "bar still in cache" );
        is( $c->get("baz"), undef, "baz no longer in cache" );
        is( $c->get("zot"), undef,, "zot no longer in cache" );
        is( $c->get("quxx"), undef, "quxx no longer in cache" );
        is( $c->get("new"), "element", "new still in cache" );
        is( $c->get("another"), "member", "another still in cache" );

        is_deeply( [ $c->get(qw(bar new nothere)) ], [ qw(lala element), undef ], "mget" );

        is( $c->_index_size, 3, "cache size" );

        $c->expire(2);

        is( $c->_index_size, 1, "expired" );

        $c->clear;

        is( $c->_index_size, 0, "no elements in cache" );
    }

    {
        my $c = $impl->new( size => 5 );

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

        cmp_ok( $hit, '<=', $c->size * 3, "no significant hits during linear scans ($hit)" );
    }
}

done_testing;

# ex: set sw=4 et:

