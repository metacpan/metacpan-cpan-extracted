#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use List::Util qw(shuffle);

my $inv;

sub invariants {
    my $self = shift;

    $inv++;

    # bugs
    fail("mru size undeflow") if $self->_mru_size < 0;
    fail("mfu size underflow") if $self->_mfu_size < 0;
    fail("mfu history size underflow") if $self->_mfu_history_size < 0;
    fail("mfu history count and list disagree") if $self->_mfu_history_size xor $self->_mfu_history_head;
    fail("mru history size underflow") if $self->_mru_history_size < 0;
    fail("mru history count and list disagree") if $self->_mru_history_size xor $self->_mru_history_head;

    # I1    0 ≤ |T1| + |T2| ≤ c.
    fail("mru + mfu size <= cache size") if $self->_mfu_size + $self->_mru_size > $self->size;

    if ( $self->isa("Cache::Ref::CART") ) {
        # I2’    0 ≤ |T2|+|B2| ≤ c.
        if ( 0 and $self->_mfu_size + $self->_mfu_history_size > $self->size ) {
            fail("mfu + mfu history size <= cache size ");
            diag sprintf "%d + %d > %d", $self->_mfu_size, $self->_mfu_history_size, $self->size;
        }

        # I3’    0 ≤ |T1|+|B1| ≤ 2c.
        fail("mru + mru history size <= cache size * 2 ") if $self->_mru_size + $self->_mru_history_size > $self->size * 2;
    } else {
        # I2    0 ≤ |T1| + |B1| ≤ c.
        fail("mru + mru history size <= cache size ") if $self->_mru_size + $self->_mru_history_size > $self->size;

        # I3    0 ≤ |T2| + |B2| ≤ 2c.
        fail("mfu + mfu history size <= cache size * 2 ") if $self->_mfu_size + $self->_mfu_history_size > $self->size * 2;
    }

    my $sum = $self->_mfu_size + $self->_mfu_history_size + $self->_mru_size + $self->_mru_history_size;

    if ( $sum > $self->size * 2 ) {
        # I4    0 ≤ |T1| + |T2| + |B1| + |B2| ≤ 2c.
        fail("sum of all sizes <= cache size * 2 ");
        diag sprintf("mfu=%d + mfuh=%d + mru=%d + mruh=%d > %d * 2",
            $self->_mfu_size, $self->_mfu_history_size,
            $self->_mru_size, $self->_mru_history_size,
            $self->size);
    }

    fail("index size > cache size * 2") if $self->_index_size > $self->size * 2;

    fail("size sums != index size") if $self->_index_size != $sum;


    # FIXME these invariants are broken on remove

    # I5    If |T1|+|T2|<c, then B1 ∪B2 is empty.
    #fail("history lists have data even though clocks aren't full")
    #    if $self->_mru_size + $self->_mfu_size < $self->size and $self->_mru_history_size || $self->_mfu_history_size;

    # I6    If |T1|+|B1|+|T2|+|B2| ≥ c, then |T1| + |T2| = c.
    #fail("clocks aren't full index size is bigger than cache size")
    #    if $self->_mru_size + $self->_mfu_size != $self->size
    #    and $self->_mfu_size + $self->_mfu_history_size + $self->_mru_size + $self->_mru_history_size >= $self->size;
    #fail("clocks aren't full index size is bigger than cache size")
    #    if $self->_mru_size + $self->_mfu_size != $self->size and $self->_index_size >= $self->size;

    # I7    Due to demand paging, once the cache is full, it remains full from then on.
}

foreach my $class (qw(Cache::Ref::CAR Cache::Ref::CART)) {
    use_ok($class);

    my $meta = $class->meta;

    $meta->make_mutable;

    foreach my $method (
        grep { /^[a-z]/ && !/^(?:size|meta)$/ }
        $meta->get_method_list
    ) {
        $meta->add_before_method_modifier($method, sub { ::invariants($_[0]) });
        $meta->add_after_method_modifier ($method, sub { ::invariants($_[0]) });
    }

    $meta->make_immutable;

    $inv = 0;

    {
        my $c = $class->new( size => 3 );

        isa_ok( $c, "Cache::Ref" );

        $c->set( foo => "blah" );

        is( $c->peek("foo"), "blah", "foo in cache" );

        $c->set( bar => "lala" );
        is( $c->peek("foo"), "blah", "foo still in cache" );
        is( $c->peek("bar"), "lala", "bar in cache" );

        $c->set( baz => "blob" );
        is( $c->peek("foo"), "blah", "foo still in cache" );
        is( $c->peek("bar"), "lala", "bar still in cache" );
        is( $c->peek("baz"), "blob", "baz in cache" );

        $c->set( zot => "quxx" );
        is( $c->peek("foo"), undef, "foo no longer in cache" );
        is( $c->peek("bar"), "lala", "bar still in cache" );
        is( $c->peek("baz"), "blob", "baz still in cache" );
        is( $c->peek("zot"), "quxx", "zot in cache" );

        $c->hit("bar");
        $c->get("baz");

        $c->set( oi => "vey" );
        is( $c->peek("foo"), undef, "foo no longer in cache" );
        is( $c->peek("bar"), "lala", "bar still in cache" );
        is( $c->peek("baz"), "blob", "baz still in cache" );
        is( $c->peek("zot"), undef, "zot no longer in cache" );
        is( $c->peek("oi"), "vey", "oi in cache" );

        $c->set( foo => "bar" );
        $c->set( bar => "baz" );

        is( $c->peek("foo"), "bar", "foo in cache" );
        is( $c->peek("bar"), "baz", "bar still in cache, new value" );
        is( $c->peek("baz"), "blob", "baz no longer in cache" );
        is( $c->peek("zot"), undef, "zot no longer in cache" );
        is( $c->peek("oi"), undef, "oi still in cache" );

        is_deeply( [ $c->peek(qw(foo bar baz nothere)) ], [ qw(bar baz blob), undef ], "mget" );

        $c->remove("foo");

        is( $c->peek("foo"), undef, "foo removed" );

        $c->expire(2);

        is_deeply( [ $c->peek(qw(foo bar baz nothere)) ], [ undef, undef, undef, undef ], "mget" );
    }

    {
        my $c = $class->new( size => 5 );

        {
            my ( $hit, $miss ) = ( 0, 0 );

            foreach my $offset ( 1 .. 100 ) {
                for ( 1 .. 100 ) {
                    # high locality of reference, should adjust to lru
                    my $key = $offset + int rand 4;

                    if ( $c->get($key) ) {
                        $hit++;
                    } else {
                        $miss++;
                        $c->set($key => $key);
                    }
                }
            }

            cmp_ok( $hit, '>=', $miss * 10, "hit rate during random access of small sigma ($hit >= $miss * 3)" );
            cmp_ok( $miss, '<=', 400, "miss rate during random access of small sigma ($miss <= max offset * 4)" );
        }

        {
            my ( $hit, $miss ) = ( 0, 0 );

            foreach my $offset ( 1 .. 100 ) {
                for ( 1 .. 30 ) {
                    # medium locality of reference,
                    my $key = $offset + int rand 8;

                    if ( $c->get($key) ) {
                        $hit++;
                    } else {
                        $miss++;
                        $c->set($key => $key);
                    }
                }
            }

            cmp_ok( $hit, '>=', $miss, "hit rate during random access of medium sigma ($hit >= $miss)" );
        }

        {
            my ( $hit, $miss ) = ( 0, 0 );

            foreach my $offset ( 1 .. 100 ) {
                for ( 1 .. 30 ) {
                    my $key = $offset + int rand 40;

                    if ( $c->get($key) ) {
                        $hit++;
                    } else {
                        $miss++;
                        $c->set($key => $key);
                    }
                }
            }

            cmp_ok( $hit, '>=', $miss / 10, "hit rate during random access of large sigma ($hit >= $miss/10)" );
        }

        {
            my ( $hit, $miss ) = ( 0, 0 );

            for ( 1 .. 100 ) {
                # biased locality of reference, like a linear scan, but with weighting
                foreach my $key ( 1 .. 3, 1 .. 3, 1 .. 12 ) {
                    if ( $c->get($key) ) {
                        $hit++;
                    } else {
                        $miss++;
                        $c->set($key => $key);
                    }
                }
            }

            cmp_ok( $hit, '>=', $miss / 2, "hit rate during small linear scans ($hit >= $miss/2)" );
        }

        {
            my ( $hit, $miss ) = ( 0, 0 );

            for ( 1 .. 100 ) {
                # biased locality of reference, like a linear scan, but with weighting
                foreach my $key ( 1 .. 3, 1 .. 20 ) {
                    if ( $c->get($key) ) {
                        $hit++;
                    } else {
                        $miss++;
                        $c->set($key => $key);
                    }
                }
            }

            if ( $c->isa("Cache::Ref::CART") ) {
                # favours LRU due to the fact that access isn't random
                cmp_ok( $hit, '>=', $miss / 10, "hit rate during medium linear scan ($hit >= $miss/10)" );
            } else {
                cmp_ok( $hit, '>=', $miss / 5, "hit rate during medium linear scan ($hit >= $miss/5)" );
            }
        }

        {
            my ( $hit, $miss ) = ( 0, 0 );

            for ( 1 .. 100 ) {
                # biased locality of reference, like a linear scan, but with weighting
                foreach my $key ( 1 .. 3, 1 .. 45 ) {
                    if ( $c->get($key) ) {
                        $hit++;
                    } else {
                        $miss++;
                        $c->set($key => $key);
                    }
                }
            }

            if ( $c->isa("Cache::Ref::CART") ) {
                # this test favours LRU, but the cache size is too small for LFU to matter over this sigma
                cmp_ok( $hit, '>=', $miss / 20, "hit rate during medium linear scan ($hit >= $miss/20)" );
            } else {
                cmp_ok( $hit, '>=', $miss / 10, "hit rate during medium linear scan ($hit >= $miss/10)" );
            }
        }

        {
            my ( $hit, $miss ) = ( 0, 0 );

            for ( 1 .. 100 ) {
                # should favour LFU
                foreach my $key ( shuffle( 1 .. 2, 1 .. 3, 1 .. 10 ) ) {
                    if ( $c->get($key) ) {
                        $hit++;
                    } else {
                        $miss++;
                        $c->set($key => $key);
                    }
                }
            }

            cmp_ok( $hit, '>=', $miss / 3, "hit rate during small sigma weighted random access ($hit >= $miss/3)" );
        }

        {
            my ( $hit, $miss ) = ( 0, 0 );

            for ( 1 .. 100 ) {
                # good for LFU with a larger history size
                foreach my $key ( shuffle(1 .. 3), shuffle(1 .. 45) ) {
                    if ( $c->get($key) ) {
                        $hit++;
                    } else {
                        $miss++;
                        $c->set($key => $key);
                    }
                }
            }

            cmp_ok( $hit, '>=', $miss / 20, "hit rate during alternating small/large random access ($hit >= $miss/20)" );
        }

        {
            my ( $hit, $miss ) = ( 0, 0 );

            for ( 1 .. 200 ) {
                # good for LFU with a large history size
                foreach my $key ( shuffle( 1 .. 2, 1 .. 3, 1 .. 45 ) ) {
                    if ( $c->get($key) ) {
                        $hit++;
                    } else {
                        $miss++;
                        $c->set($key => $key);
                    }
                }
            }

            cmp_ok( $hit, '>=', $miss / 10, "hit rate during large weighted sigma, random access ($hit >= $miss/10)" );
        }
    }

    cmp_ok( $inv, '>=', 1000, "invariants ran at least a few times" );
}

done_testing;

# ex: set sw=4 et:

