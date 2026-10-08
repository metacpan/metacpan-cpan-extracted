use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::HashMap::Shared::II;

my $dir = tempdir( CLEANUP => 1 );

# the seal lives in the shared header, so a handle opened read-write before the
# freeze must honour it too
{
    my $p = "$dir/seal.shm";
    my $w = Data::HashMap::Shared::II->new( $p, 1024 );
    $w->put( 1, 100 );
    my $f = Data::HashMap::Shared::II->new( $p, 1024 );
    $f->freeze;

    ok $f->frozen, 'map reports frozen';
    ok !eval { $w->put( 2, 200 ); 1 }, 'a handle opened before the freeze cannot write';
    like $@, qr/is frozen \(read-only\)/, '  ... and says why';

    my $ro = Data::HashMap::Shared::II->new_readonly($p);
    is $ro->get(2), undef, 'the sealed map never saw the write';
    is $ro->get(1), 100,   '  ... and still holds what was there before';
}

{
    my $p = "$dir/seal_sharded";
    my $w = Data::HashMap::Shared::II->new_sharded( $p, 4, 1024 );
    $w->put( 1, 100 );
    my $f = Data::HashMap::Shared::II->new_sharded( $p, 4, 1024 );
    $f->freeze;
    ok !eval { $w->put( 2, 200 ); 1 }, 'sharded: pre-freeze handle cannot write';
}

# sizes reach the C layer as uint32_t: 2**32+100 must not truncate to 100
{
    ok !eval { Data::HashMap::Shared::II->new( undef, 2**32 + 100 ); 1 },
        'max_entries beyond 32 bits croaks instead of truncating';
    like $@, qr/max_entries/, '  ... naming the argument';

    my $ok = Data::HashMap::Shared::II->new( undef, 1024 );
    cmp_ok $ok->max_entries, '>=', 1024, 'an ordinary size still works';
}

# the shard count is rounded up to a power of two; above 2**31 that shift
# wraps to zero
{
    ok !eval { Data::HashMap::Shared::II->new_sharded( "$dir/ns", 2**31 + 1, 64 ); 1 },
        'an absurd shard count croaks rather than hanging';
    like $@, qr/num_shards/, '  ... naming the argument';

    my $s = Data::HashMap::Shared::II->new_sharded( "$dir/ns_ok", 6, 1024 );
    $s->put( 1, 10 );
    is $s->get(1), 10, 'a sane shard count still rounds up and works';
}

# drain(limit) caps the limit at the live entry count; max_size is 0
# (unbounded) on a map without LRU
{
    for my $v (
        [ II => 'Data::HashMap::Shared::II', 1,     10 ],
        [ SS => 'Data::HashMap::Shared::SS', 'k',   'v' ],
        [ IS => 'Data::HashMap::Shared::IS', 1,     'v' ],
        [ SI => 'Data::HashMap::Shared::SI', 'k',   1 ],
        )
    {
        my ( $name, $class, $k, $val ) = @$v;
        eval "require $class" or next;
        my $m = $class->new( "$dir/drain_$name", 1024 );
        is $m->max_size, 0, "$name: no LRU bound configured";
        $m->put( $k, $val );
        my @got = $m->drain(1_000_000);
        is scalar @got, 2, "$name: an oversized limit still drains the entry";
        is $m->size, 0, "$name: ... and empties the map";
    }
}

done_testing;
