use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::HashMap::Shared::II;

my $dir = tempdir( CLEANUP => 1 );

# ---------------------------------------------------------------------------
# The seal lives in the shared header, so a handle opened read-write BEFORE the
# freeze must honour it too. Checking only the process-local readonly flag let
# such a handle keep writing into a map documented as permanently immutable,
# and a new_readonly consumer then observed the mutation.
# ---------------------------------------------------------------------------
{
    my $p = "$dir/seal.shm";
    my $w = Data::HashMap::Shared::II->new( $p, 1024 );   # opened before the freeze
    $w->put( 1, 100 );
    my $f = Data::HashMap::Shared::II->new( $p, 1024 );
    $f->freeze;

    ok $f->frozen, 'map reports frozen';
    ok !eval { $w->put( 2, 200 ); 1 }, 'a handle opened before the freeze cannot write';
    like $@, qr/frozen|read-only/i, '  ... and says why';

    my $ro = Data::HashMap::Shared::II->new_readonly($p);
    is $ro->get(2), undef, 'the sealed map never saw the write';
    is $ro->get(1), 100,   '  ... and still holds what was there before';
}

# same, through a sharded map: freeze recurses into the shards
{
    my $p = "$dir/seal_sharded";
    my $w = Data::HashMap::Shared::II->new_sharded( $p, 4, 1024 );
    $w->put( 1, 100 );
    my $f = Data::HashMap::Shared::II->new_sharded( $p, 4, 1024 );
    $f->freeze;
    ok !eval { $w->put( 2, 200 ); 1 }, 'sharded: pre-freeze handle cannot write';
}

# ---------------------------------------------------------------------------
# Constructor sizes are handed to the C layer as uint32_t. Without a range
# check new($path, 2**32+100) silently built a 100-entry map -- the caller asks
# for four billion and gets a hundred, with nothing said.
# ---------------------------------------------------------------------------
{
    ok !eval { Data::HashMap::Shared::II->new( undef, 2**32 + 100 ); 1 },
        'max_entries beyond 32 bits croaks instead of truncating';
    like $@, qr/max_entries/, '  ... naming the argument';

    my $ok = Data::HashMap::Shared::II->new( undef, 1024 );
    cmp_ok $ok->max_entries, '>=', 1024, 'an ordinary size still works';
}

# ---------------------------------------------------------------------------
# new_sharded rounded the shard count up to a power of two with `ns <<= 1`.
# Above 2**31 that shifts to zero and the loop never terminates.
# ---------------------------------------------------------------------------
{
    ok !eval { Data::HashMap::Shared::II->new_sharded( "$dir/ns", 2**31 + 1, 64 ); 1 },
        'an absurd shard count croaks rather than hanging';
    like $@, qr/num_shards/, '  ... naming the argument';

    my $s = Data::HashMap::Shared::II->new_sharded( "$dir/ns_ok", 6, 1024 );
    $s->put( 1, 10 );
    is $s->get(1), 10, 'a sane shard count still rounds up and works';
}

# ---------------------------------------------------------------------------
# drain(limit) caps limit at what the map can actually yield so that a huge
# limit does not reserve a huge buffer. The cap has to be the live entry count:
# max_size is the configured LRU bound and is 0 -- meaning unbounded -- on every
# map that never set one, so capping with it drained nothing at all.
# ---------------------------------------------------------------------------
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
        my $m = $class->new( "$dir/drain_$name", 1024 );   # no max_size
        is $m->max_size, 0, "$name: no LRU bound configured";
        $m->put( $k, $val );
        my @got = $m->drain(1_000_000);
        is scalar @got, 2, "$name: an oversized limit still drains the entry";
        is $m->size, 0, "$name: ... and empties the map";
    }
}

done_testing;
