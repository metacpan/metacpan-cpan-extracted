#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use ok 'Cache::Ref::LRU';

foreach my $lru ( map { "Cache::Ref::Util::LRU::$_" } qw(Array List) ) {
    use_ok($lru);

    {
        my $c = Cache::Ref::LRU->new( size => 3, lru_class => $lru );

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

        {
            my $ran = 0;
            $c->compute( baz => sub { $ran++ } );
            ok( !$ran, "did not compute" );
        }

        {
            my $ran = 0;
            $c->compute( zot => sub { $ran++; "quxx" } );
            ok( $ran, "did compute" );
        }

        is( $c->get("foo"), undef, "foo no longer in cache" );
        is( $c->get("bar"), "lala", "bar still in cache" );
        is( $c->get("baz"), "blob", "baz still in cache" );
        is( $c->get("zot"), "quxx", "zot in cache" );

        $c->hit("bar");
        is( $c->_lru->mru, "bar", "mru" );
        is( $c->_lru->lru, "baz", "lru" );

        $c->set( oi => "vey" );
        is( $c->get("foo"), undef, "foo no longer in cache" );
        is( $c->get("bar"), "lala", "bar still in cache" );
        is( $c->get("baz"), undef, "baz no longer in cache" );
        is( $c->get("zot"), "quxx", "zot still in cache" );
        is( $c->get("oi"), "vey", "oi in cache" );

        $c->set( foo => "brrr" );
        $c->set( foo => "bar" );
        $c->set( bar => "baz" );

        is( $c->get("foo"), "bar", "foo in cache" );
        is( $c->get("bar"), "baz", "bar still in cache, new value" );
        is( $c->get("baz"), undef, "baz no longer in cache" );
        is( $c->get("zot"), undef, "zot no longer in cache" );
        is( $c->get("oi"), "vey", "oi still in cache" );

        is_deeply( [ $c->get(qw(foo bar nothere)) ], [ qw(bar baz), undef ], "mget" );

        $c->remove("oi");

        is( $c->get("oi"), undef, "oi removed from cache" );

        is( $c->_index_size, 2, "two elements in cache" );

        $c->expire(1);

        is( $c->_index_size, 1, "expired one entry" );

        $c->clear;

        is( $c->_index_size, 0, "cache is empty" );
    }

    {
        my $c = Cache::Ref::LRU->new( size => 5, lru_class => $lru );

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

