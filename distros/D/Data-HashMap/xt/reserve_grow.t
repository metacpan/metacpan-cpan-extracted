use strict;
use warnings;
use Test::More;

use Data::HashMap::II;
use Data::HashMap::SS;

# ---- reserve(N) followed by put_ttl: expires_at must size to reserved cap ----

{
    my $m = Data::HashMap::II->new();
    $m->reserve(1024);
    # First put_ttl triggers HM_LAZY_ALLOC_EXPIRES over current capacity
    $m->put_ttl($_, $_, 100) for 1..500;
    is $m->size, 500, 'reserve + put_ttl: inserts counted';
    # After reserve grew the table, lazy-alloc of expires_at must cover it
    for (1..500) { is $m->get($_), $_ } ; # many subtests — keep running
}

# ---- reserve then grow past reserved capacity via load ----

{
    my $m = Data::HashMap::II->new();
    $m->reserve(16);
    # Push well past 16 — triggers resize
    $m->put($_, $_ * 2) for 1..200;
    is $m->size, 200, 'reserve-then-overflow: resizes correctly';
    is $m->get(150), 300, 'post-resize retrieval';
}

# ---- reserve(0) + normal usage ----

{
    my $m = Data::HashMap::II->new();
    $m->reserve(0);
    $m->put(1, 1);
    is $m->get(1), 1, 'reserve(0) is a no-op';
}

# ---- SS reserve + mixed TTL/non-TTL ----

{
    my $m = Data::HashMap::SS->new();
    $m->reserve(512);
    $m->put_ttl("k$_", "v$_", 100) for 1..100;
    $m->put("p$_", "q$_") for 1..100;
    is $m->size, 200, 'mixed TTL/non-TTL put after reserve';
    is $m->get("k50"), "v50", 'TTL entry retrievable';
    is $m->get("p50"), "q50", 'non-TTL entry retrievable';
}

done_testing;
