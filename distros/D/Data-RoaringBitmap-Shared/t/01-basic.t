use strict;
use warnings;
use Test::More;
use Data::RoaringBitmap::Shared;

# Numeric sort helper. Defined as a sub so its $a/$b are the sort package
# variables, never shadowed by a lexical bitmap named $a or $b in a caller.
sub nsort { sort { $a <=> $b } @_ }

# ---- constructor + initial state ----
{
    my $a = Data::RoaringBitmap::Shared->new(undef, 256);
    isa_ok $a, 'Data::RoaringBitmap::Shared';
    ok !defined($a->path), 'anonymous path is undef';
    is $a->cardinality, 0, 'fresh bitmap has cardinality 0';
    is $a->count, 0, 'count is an alias for cardinality';
    is $a->size, 0, 'size is an alias for cardinality';
    ok $a->is_empty, 'is_empty true on a fresh bitmap';
    ok !$a->contains(123), 'nothing is contained in a fresh bitmap';
    ok !defined($a->min), 'min of empty is undef';
    ok !defined($a->max), 'max of empty is undef';
    is_deeply $a->to_array, [], 'to_array of empty is []';
}

# ---- basic add / contains / remove ----
{
    my $a = Data::RoaringBitmap::Shared->new(undef, 256);
    is $a->add(5), 1, 'add(5) returns 1 (new)';
    is $a->add(5), 0, 'add(5) again returns 0 (already present)';
    ok $a->contains(5), 'contains(5)';
    ok $a->test(5), 'test is an alias for contains';
    ok !$a->contains(6), '!contains(6)';
    is $a->cardinality, 1, 'cardinality 1';
    ok !$a->is_empty, '!is_empty after add';

    is $a->set(7), 1, 'set is an alias for add';
    is $a->cardinality, 2, 'cardinality 2 after set(7)';

    is $a->remove(5), 1, 'remove(5) returns 1';
    is $a->delete(7), 1, 'delete is an alias for remove';
    ok !$a->contains(5), '!contains(5) after remove';
    is $a->remove(5), 0, 'remove of absent value returns 0';
    is $a->cardinality, 0, 'cardinality 0 after removing both';
    ok $a->is_empty, 'is_empty again';
}

# ---- 0 and 2**32-1 are valid members ----
{
    my $a = Data::RoaringBitmap::Shared->new(undef, 256);
    is $a->add(0), 1, 'add(0) returns 1';
    ok $a->contains(0), 'contains(0)';
    is $a->add(4294967295), 1, 'add(2**32-1) returns 1';
    ok $a->contains(4294967295), 'contains(2**32-1)';
    is $a->min, 0, 'min is 0';
    is $a->max, 4294967295, 'max is 2**32-1';
    is $a->cardinality, 2, 'cardinality 2';
}

# ---- array -> bitmap conversion: 5000 values in ONE bucket ----
{
    my $a = Data::RoaringBitmap::Shared->new(undef, 256);
    # 0..4999 all share high16 == 0 -> one bucket, crosses the 4096 array cap
    $a->add($_) for 0 .. 4999;
    is $a->cardinality, 5000, 'cardinality 5000 in a single bucket';
    my $missing = 0;
    $missing++ for grep { !$a->contains($_) } 0 .. 4999;
    is $missing, 0, 'all 5000 values contained after array->bitmap promotion';
    ok !$a->contains(5000), 'a non-member just past the range is absent';

    my $st = $a->stats;
    is $st->{buckets_used}, 1, 'exactly one bucket used';
    is $st->{containers_used}, 2, 'one container slot used (plus reserved slot 0)';
    is $st->{cardinality}, 5000, 'stats cardinality matches';

    is $a->min, 0, 'min 0 in the dense bucket';
    is $a->max, 4999, 'max 4999 in the dense bucket';

    # to_array on a dense (bitmap) bucket returns the sorted elements
    is_deeply $a->to_array, [0 .. 4999], 'to_array on a bitmap bucket is sorted 0..4999';

    # remove some, then re-check (stays a bitmap; v1 has no down-convert)
    is $a->remove(2500), 1, 'remove from the bitmap bucket';
    is $a->remove(0), 1, 'remove min from the bitmap bucket';
    is $a->remove(4999), 1, 'remove max from the bitmap bucket';
    is $a->cardinality, 4997, 'cardinality dropped by 3';
    ok !$a->contains(2500), '2500 removed';
    is $a->min, 1, 'min recomputed to 1 after removing 0';
    is $a->max, 4998, 'max recomputed to 4998 after removing 4999';

    # remove the rest -> bucket frees its slot
    $a->remove($_) for 1 .. 4998;
    is $a->cardinality, 0, 'all removed from the bucket';
    is $a->stats->{buckets_used}, 0, 'bucket freed once emptied';
    # containers_used is a high-water mark: freeing a slot puts it on the
    # freelist but does not lower the high-water (it only resets on clear).
    my $hw = $a->stats->{containers_used};
    # the freed slot is recycled: re-adding into a fresh bucket reuses it
    # rather than bumping the high-water further.
    $a->add(123);
    is $a->stats->{containers_used}, $hw, 'freed container slot is recycled (high-water unchanged)';
    is $a->stats->{buckets_used}, 1, 'one bucket again after re-add';
}

# ---- values across MANY buckets ----
{
    my $a = Data::RoaringBitmap::Shared->new(undef, 256);
    # k*70000 for k=0..100 -> 101 distinct high16 groups (70000 > 65536)
    my @vals = map { $_ * 70000 } 0 .. 100;
    $a->add($_) for @vals;
    is $a->cardinality, 101, 'cardinality 101 across many buckets';
    is $a->min, 0, 'min is 0';
    is $a->max, 100 * 70000, 'max is 100*70000';
    is $a->stats->{buckets_used}, 101, '101 buckets used';
    my $bad = 0;
    $bad++ for grep { !$a->contains($_) } @vals;
    is $bad, 0, 'every spread value is contained';
    is_deeply $a->to_array, [nsort @vals], 'to_array spans the buckets sorted';
}

# ---- add_many + to_array round-trip ----
{
    my $a = Data::RoaringBitmap::Shared->new(undef, 256);
    my @vals = (100, 5, 5, 70000, 3, 65536, 65535, 0);
    my $added = $a->add_many(\@vals);
    my %uniq = map { $_ => 1 } @vals;
    is $added, scalar(keys %uniq), 'add_many returns the number newly added (dedup)';
    is $a->cardinality, scalar(keys %uniq), 'cardinality equals distinct count';
    is_deeply $a->to_array, [nsort keys %uniq], 'to_array returns the sorted distinct values';
    # adding again adds nothing new
    is $a->add_many(\@vals), 0, 'add_many of the same values adds 0';
}

# ---- union ----
{
    my $a = Data::RoaringBitmap::Shared->new(undef, 256);
    my $b = Data::RoaringBitmap::Shared->new(undef, 256);
    $a->add_many([1, 2, 3]);
    $b->add_many([3, 4, 5]);
    my $ret = $a->union($b);
    isa_ok $ret, 'Data::RoaringBitmap::Shared', 'union returns an object';
    is $a->cardinality, 5, 'a = {1,2,3,4,5} after union, cardinality 5';
    is_deeply $a->to_array, [1, 2, 3, 4, 5], 'union contents correct';
    is $b->cardinality, 3, 'union did not modify the other bitmap';

    # 'or' alias
    my $c = Data::RoaringBitmap::Shared->new(undef, 256);
    $c->add_many([10, 20]);
    $a->or($c);
    is_deeply $a->to_array, [1, 2, 3, 4, 5, 10, 20], 'or is an alias for union';
}

# ---- intersect ----
{
    my $a = Data::RoaringBitmap::Shared->new(undef, 256);
    my $b = Data::RoaringBitmap::Shared->new(undef, 256);
    $a->add_many([1, 2, 3, 4]);
    $b->add_many([2, 4, 6]);
    $a->intersect($b);
    is $a->cardinality, 2, 'a = {2,4} after intersect';
    is_deeply $a->to_array, [2, 4], 'intersect contents correct';
    is $b->cardinality, 3, 'intersect did not modify the other bitmap';

    # 'and' alias, and an intersect that empties a bucket
    my $c = Data::RoaringBitmap::Shared->new(undef, 256);
    $c->add_many([99, 100]);
    $a->and($c);
    is $a->cardinality, 0, 'and is an alias; disjoint intersect empties the set';
    is $a->stats->{buckets_used}, 0, 'emptied buckets freed by intersect';
}

# ---- union / intersect mixing array and bitmap containers ----
{
    # a: dense bucket 0 (bitmap, 0..4999) + sparse value in bucket 1
    my $a = Data::RoaringBitmap::Shared->new(undef, 256);
    $a->add($_) for 0 .. 4999;          # bitmap container in bucket 0
    $a->add(70000);                     # array container in bucket 1

    # b: sparse bucket 0 (array) overlapping + dense bucket 1 (bitmap)
    my $b = Data::RoaringBitmap::Shared->new(undef, 256);
    $b->add_many([10, 4999, 5000, 6000]);     # array in bucket 0 (5000,6000 are new to bucket 0)
    $b->add(70000 + $_) for 0 .. 4999;        # bitmap in bucket 1 (incl. 70000)

    # union: array|bitmap (bucket0) and array(a)|bitmap(b) (bucket1)
    my $u = Data::RoaringBitmap::Shared->new(undef, 256);
    $u->add($_) for 0 .. 4999;
    $u->add(70000);
    $u->union($b);
    # expected bucket0 = {0..4999} U {10,4999,5000,6000} = 0..5000 + 6000
    # expected bucket1 = {70000} U {70000..74999} = 70000..74999
    my %exp;
    $exp{$_} = 1 for 0 .. 5000;
    $exp{6000} = 1;
    $exp{$_} = 1 for map { 70000 + $_ } 0 .. 4999;
    is $u->cardinality, scalar(keys %exp), 'mixed-container union cardinality matches';
    is_deeply $u->to_array, [nsort keys %exp], 'mixed-container union contents match';

    # intersect: bitmap(a bucket0) & array(b bucket0); array(a bucket1) & bitmap(b bucket1)
    my $i = Data::RoaringBitmap::Shared->new(undef, 256);
    $i->add($_) for 0 .. 4999;
    $i->add(70000);
    $i->intersect($b);
    # bucket0: {0..4999} & {10,4999,5000,6000} = {10,4999}
    # bucket1: {70000} & {70000..74999} = {70000}
    is_deeply $i->to_array, [10, 4999, 70000], 'mixed-container intersect contents match';
    is $i->cardinality, 3, 'mixed-container intersect cardinality 3';
}

# union pairing both operands hold a BITMAP container in the same bucket
# (exercises the bitmap|bitmap arm of rb_or_into_bitmap, otherwise untested)
{
    my $x = Data::RoaringBitmap::Shared->new(undef, 256);
    my $y = Data::RoaringBitmap::Shared->new(undef, 256);
    $x->add($_) for 0 .. 4999;        # >4096 in bucket 0 -> bitmap container
    $y->add($_) for 2500 .. 7499;     # >4096 in bucket 0 -> bitmap container
    $x->union($y);
    is $x->cardinality, 7500, 'bitmap|bitmap union cardinality';
    is_deeply $x->to_array, [0 .. 7499], 'bitmap|bitmap union contents';
}

# ---- self-union / self-intersect are no-ops ----
{
    my $a = Data::RoaringBitmap::Shared->new(undef, 256);
    $a->add_many([1, 2, 3, 70000]);
    $a->union($a);
    is_deeply $a->to_array, [1, 2, 3, 70000], 'self-union is a no-op';
    $a->intersect($a);
    is_deeply $a->to_array, [1, 2, 3, 70000], 'self-intersect is a no-op';
    is $a->cardinality, 4, 'cardinality unchanged after self ops';
}

# ---- clear ----
{
    my $a = Data::RoaringBitmap::Shared->new(undef, 256);
    $a->add($_) for (1, 2, 3, 70000, 140000);
    $a->add($_) for 0 .. 4999;          # also a dense bucket
    cmp_ok $a->cardinality, '>', 0, 'non-empty before clear';
    $a->clear;
    is $a->cardinality, 0, 'cardinality 0 after clear';
    ok !$a->contains(2), '!contains after clear';
    is $a->stats->{buckets_used}, 0, 'no buckets used after clear';
    is $a->stats->{containers_used}, 1, 'pool reset after clear';
    # usable again
    is $a->add(42), 1, 'add after clear works';
    is $a->cardinality, 1, 'cardinality 1 after re-add';
}

# ---- stats keys ----
{
    my $a = Data::RoaringBitmap::Shared->new(undef, 256);
    $a->add_many([1, 2, 70000]);
    my $st = $a->stats;
    is ref($st), 'HASH', 'stats returns a hashref';
    ok exists $st->{$_}, "stats has $_"
        for qw(cardinality containers_used containers_capacity buckets_used ops mmap_size);
    is $st->{cardinality}, 3, 'stats cardinality == 3';
    is $st->{containers_capacity}, 256, 'stats containers_capacity matches';
    is $st->{buckets_used}, 2, 'two buckets used (high16 0 and 1)';
    cmp_ok $st->{containers_used}, '>=', 2, 'containers_used >= 2 (plus reserved)';
    cmp_ok $st->{ops}, '>', 0, 'ops counted the writes';
    cmp_ok $st->{mmap_size}, '>', 0, 'mmap_size > 0';
}

# ---- error paths ----

# add of a value exceeding uint32 croaks
{
    my $a = Data::RoaringBitmap::Shared->new(undef, 256);
    ok !eval { $a->add(2**32); 1 }, 'add(2**32) croaks';
    like $@, qr/exceeds uint32/, 'add(2**32) croak mentions uint32';
    ok !eval { $a->add_many([1, 2**32, 3]); 1 }, 'add_many with an oversized value croaks';
    like $@, qr/exceeds uint32/, 'add_many oversized croak mentions uint32';
    # contains / remove of an out-of-range value do NOT croak; just absent / no-op
    ok !$a->contains(2**32), 'contains of an out-of-range value is false (no croak)';
    is $a->remove(2**32), 0, 'remove of an out-of-range value returns 0 (no croak)';
}

# constructor: container_capacity 0 rejected
ok !eval { Data::RoaringBitmap::Shared->new(undef, 0); 1 }, 'new(0) croaks';
like $@, qr/container_capacity must be/, 'new(0) croak mentions container_capacity';
ok !eval { Data::RoaringBitmap::Shared->new_memfd('x', 0); 1 }, 'new_memfd(0) croaks';
like $@, qr/container_capacity must be/, 'new_memfd(0) croak mentions container_capacity';

# constructor: above the ceiling rejected (validated before any mmap)
ok !eval { Data::RoaringBitmap::Shared->new(undef, (1 << 20) + 1); 1 }, 'new(> max) croaks';
like $@, qr/container_capacity/i, 'oversized capacity croak mentions container_capacity';

# ---- container-pool exhaustion: many distinct buckets ----
{
    # tiny pool: only a couple of usable slots. Each value in a fresh high16
    # bucket needs a new container slot, so enough distinct buckets must croak.
    my $a = Data::RoaringBitmap::Shared->new(undef, 3);   # slots 0(reserved),1,2 -> 2 usable
    my @ok;
    my $croaked = 0;
    for my $k (0 .. 50) {
        my $x = $k * 70000;     # each lands in a distinct bucket
        if (eval { $a->add($x); 1 }) {
            push @ok, $x;
        } else {
            like $@, qr/exhausted/, 'pool exhaustion croak mentions exhausted';
            $croaked = 1;
            last;
        }
    }
    ok $croaked, 'adding values in many distinct buckets eventually croaks on pool exhaustion';
    is scalar(@ok), 2, 'exactly the 2 usable slots were filled before the croak';
    # the bitmap stays usable: pre-exhaustion values still present
    my $bad = 0;
    $bad++ for grep { !$a->contains($_) } @ok;
    is $bad, 0, 'all pre-exhaustion values still contained after the croak';
    is $a->cardinality, scalar(@ok), 'cardinality equals successful adds';
    # adding to an EXISTING bucket still works after exhaustion (no new slot)
    is $a->add($ok[0] + 1), 1, 'adding into an already-allocated bucket still works after exhaustion';
}

# ---- add_many mid-batch pool exhaustion (non-atomic, documented) ----
{
    # container_cap 3 -> slots 0(reserved),1,2 -> only 2 usable. The batch spans
    # 5 distinct high16 buckets, so add_many must run out partway and croak.
    my $a = Data::RoaringBitmap::Shared->new(undef, 3);
    my @vals = (0, 70000, 140000, 210000, 280000);   # 5 distinct buckets
    ok !eval { $a->add_many(\@vals); 1 }, 'add_many croaks when the pool runs out mid-batch';
    like $@, qr/exhaust/, 'add_many mid-batch croak mentions exhaustion';
    # The 2 elements added before exhaustion remain members (non-atomic).
    is $a->cardinality, 2, 'exactly the 2 usable slots were filled before the croak';
    ok $a->contains(0),     'first pre-exhaustion element still present';
    ok $a->contains(70000), 'second pre-exhaustion element still present';
    ok !$a->contains(140000), 'the element that hit exhaustion was not added';
    # A follow-up contains() under an alarm proves the write lock was released.
    my $survived = eval {
        local $SIG{ALRM} = sub { die "hung\n" };
        alarm 5;
        my $v = $a->contains(0);   # read lock -- would hang if add_many leaked the write lock
        alarm 0;
        $v;
    };
    is $survived, 1, 'lock not leaked after the add_many mid-batch exhaustion croak';
}

# ---- set op on two SEPARATE handles to the SAME backing bitmap is a no-op ----
# Regression guard for the cross-process lock-ordering fix: ordering keyed on a
# shared-memory bitmap identity (not the process-local handle pointer) means two
# distinct handles to one mapping are detected as the same bitmap and the op is a
# pure no-op -- it must NOT try to take both the write and read lock on the one
# shared rwlock (which would self-deadlock). An alarm makes a regression fail
# loudly instead of hanging forever.
{
    my $sp = "/tmp/rb-sameid-$$.bin";
    unlink $sp;
    my $h1 = Data::RoaringBitmap::Shared->new($sp, 256);
    $h1->add_many([1, 2, 3, 70000]);
    my $h2 = Data::RoaringBitmap::Shared->new($sp, 256);   # second handle, same file
    ok $h2->contains(70000), 'second handle sees the first handle writes (same mapping)';

    my $ok = eval {
        local $SIG{ALRM} = sub { die "hung\n" };
        alarm 5;
        $h1->union($h2);        # same underlying bitmap -> no-op, must not deadlock
        $h1->intersect($h2);    # likewise
        $h2->union($h1);        # and the reverse direction
        alarm 0;
        1;
    };
    ok $ok, 'union/intersect across two handles to one bitmap did not hang';
    is_deeply $h1->to_array, [1, 2, 3, 70000], 'same-bitmap union/intersect left contents unchanged (no-op)';
    is $h1->cardinality, 4, 'same-bitmap set ops did not change cardinality';

    # And the degenerate self case under an alarm, for good measure.
    my $self_ok = eval {
        local $SIG{ALRM} = sub { die "hung\n" };
        alarm 5;
        $h1->union($h1);
        $h1->intersect($h1);
        alarm 0;
        1;
    };
    ok $self_ok, 'self union/intersect did not hang';
    is_deeply $h1->to_array, [1, 2, 3, 70000], 'self set ops are a no-op';

    undef $h1; undef $h2;
    unlink $sp;
}

# ---- union that needs more slots than available croaks (and leaves a unchanged) ----
{
    my $a = Data::RoaringBitmap::Shared->new(undef, 2);   # 1 usable slot
    my $b = Data::RoaringBitmap::Shared->new(undef, 8);
    $a->add(5);                       # uses a's only usable slot (bucket 0)
    $b->add_many([5, 70000, 140000]); # buckets 0,1,2 -> a lacks 1 and 2 (needs 2 new slots, has 0)
    ok !eval { $a->union($b); 1 }, 'union that needs unavailable slots croaks';
    like $@, qr/exhausted/, 'union exhaustion croak mentions exhausted';
    # a is unchanged (the pre-check croaked before mutating)
    is $a->cardinality, 1, 'a unchanged after the failed union';
    is_deeply $a->to_array, [5], 'a still {5} after the failed union';
}

# ---- reopen persists ----
my $path = "/tmp/rb-basic-$$.bin";
unlink $path;
{
    my $w = Data::RoaringBitmap::Shared->new($path, 256);
    is $w->path, $path, 'file-backed path';
    $w->add_many([1, 2, 3, 70000, 140000]);
    $w->add($_) for 1000 .. 5500;    # a dense bucket (becomes a bitmap)
    is $w->cardinality, 5 + 4501, 'writer added the values';
    $w->sync;
}
{
    my $r = Data::RoaringBitmap::Shared->new($path, 256);
    is $r->cardinality, 5 + 4501, 'reopen: cardinality persisted';
    ok $r->contains(70000), 'reopen: a spread value persisted';
    ok $r->contains(3000), 'reopen: a dense-bucket value persisted';
    ok !$r->contains(6000), 'reopen: a non-member is still absent';
    is $r->min, 1, 'reopen: min persisted';
    is $r->max, 140000, 'reopen: max persisted';
}
# corrupt file rejected
{ open my $fh, '>', $path or die $!; print $fh "junk"; close $fh; }
ok !eval { Data::RoaringBitmap::Shared->new($path, 256); 1 }, 'too-small/corrupt file rejected';
unlink $path;

# ---- class-method unlink ----
my $cu = "/tmp/rb-cu-$$.bin";
unlink $cu;
{ my $w = Data::RoaringBitmap::Shared->new($cu, 16); $w->sync; }
ok -e $cu, 'backing file exists';
Data::RoaringBitmap::Shared->unlink($cu);
ok !-e $cu, 'class-method unlink removed the file';

# ---- instance-method unlink ----
my $iu = "/tmp/rb-iu-$$.bin";
unlink $iu;
{
    my $w = Data::RoaringBitmap::Shared->new($iu, 16);
    ok -e $iu, 'instance backing file exists';
    $w->unlink;
    ok !-e $iu, 'instance-method unlink removed the file';
}

# ---- memfd round-trip shares the bitmap ----
{
    my $m  = Data::RoaringBitmap::Shared->new_memfd('rb', 256);
    my $fd = $m->memfd;
    cmp_ok $fd, '>=', 0, 'memfd fd >= 0';
    my $m2 = Data::RoaringBitmap::Shared->new_from_fd($fd);
    cmp_ok $m2->memfd, '>=', 0, 'new_from_fd exposes its (dup) backing fd';
    $m->add(11);
    ok $m2->contains(11), 'new_from_fd shares the bitmap';
    $m2->add(22);
    ok $m->contains(22), 'writes from the reopened handle are visible';
    ok !defined($m2->path), 'new_from_fd path is undef';
    my $mu = Data::RoaringBitmap::Shared->new_memfd(undef, 16);
    cmp_ok $mu->memfd, '>=', 0, 'new_memfd with undef name uses a default label';
}

# new_from_fd rejects a non-RB file
{
    my $jp = "/tmp/rb-junkfd-$$.bin";
    unlink $jp;
    open my $fh, '+>', $jp or die $!;
    print $fh "not a roaring-bitmap table";
    $fh->flush if $fh->can('flush');
    ok !eval { Data::RoaringBitmap::Shared->new_from_fd(fileno($fh)); 1 },
        'new_from_fd rejects a non-RB file';
    like $@, qr/too small|invalid|roaring/, 'new_from_fd junk-file croak message';
    close $fh;
    unlink $jp;
}

# ---- lock-leak regression ----
# add(2**32) croaks BEFORE the write lock is taken (the range check is first).
# A follow-up contains() under a 5s alarm proves the lock was not leaked.
{
    my $a = Data::RoaringBitmap::Shared->new(undef, 256);
    $a->add(1);
    ok !eval { $a->add(2**32); 1 }, 'oversized add croaks';
    my $survived = eval {
        local $SIG{ALRM} = sub { die "hung\n" };
        alarm 5;
        my $v = $a->contains(1);   # takes the read lock -- would hang if a write lock leaked
        alarm 0;
        $v;
    };
    is $survived, 1, 'lock not leaked: contains works after the caught oversized croak';
}

# also: a pool-exhaustion croak releases the write lock before croaking.
{
    my $a = Data::RoaringBitmap::Shared->new(undef, 2);   # 1 usable slot
    for my $k (0 .. 9) { last unless eval { $a->add($k * 70000); 1 }; }
    my $survived = eval {
        local $SIG{ALRM} = sub { die "hung\n" };
        alarm 5;
        my $c = $a->cardinality;    # takes the read lock -- would hang if the write lock leaked
        alarm 0;
        1;
    };
    ok $survived, 'lock not leaked after a pool-exhaustion croak';
}

# ---- DESTROY nulls the handle ----
{
    my $i = Data::RoaringBitmap::Shared->new(undef, 256);
    $i->add(1);
    $i->DESTROY;
    eval { $i->contains(1) };
    like $@, qr/destroyed/, 'use after DESTROY croaks (not a use-after-free)';
    eval { $i->DESTROY };
    pass 'double DESTROY did not crash';
}

done_testing;
