use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::RoaringBitmap::Shared;

# A frozen roaring bitmap must be queryable lock-free through a PROT_READ view.
# The hard part is the mix of container kinds: a dense bucket becomes a BITMAP
# container, a sparse bucket stays an ARRAY container.  Every read/query must
# work on the read-only mapping without taking the reader-slots rwlock (which
# writes shared memory -> SIGSEGV on PROT_READ) and without lazily normalizing
# or caching anything back into the mapping.
#
# NOTE: this build is v1 (array + bitmap containers only -- no run containers),
# so a "run" of consecutive integers is stored as an array container (if the
# bucket stays under 4096 members) or a bitmap container (if it grows past it),
# not a distinct run container.  We exercise both kinds that exist.

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/frozen.rb";

# high<<16 bases for three distinct buckets
my $B0 = 0;              # bucket 0
my $B5 = 5 << 16;        # bucket 5  (327680)
my $B10 = 10 << 16;      # bucket 10 (655360)

# bucket 0: dense range 0..5000 (5001 members > 4096) -> BITMAP container
my @dense = (0 .. 5000);
# bucket 5: three scattered members -> ARRAY container
my @sparse = ($B5 | 1, $B5 | 1000, $B5 | 40000);
# bucket 10: a run of 201 consecutive members (< 4096) -> ARRAY container
my @run = map { $B10 | $_ } (100 .. 300);

my @all      = (@dense, @sparse, @run);
my $card     = scalar @all;              # 5001 + 3 + 201 = 5205
my $min      = 0;                        # bucket 0, member 0
my $max      = $B10 | 300;              # bucket 10, member 300 (655660)
my %present  = map { $_ => 1 } @all;
my @absent   = (5001, $B5 | 2, $B10 | 500, 900000, 4294967295);

# ---- producer: build a mixed-container bitmap, freeze it ----
{
    my $rb = Data::RoaringBitmap::Shared->new($path, 256);
    ok !$rb->frozen,   'freshly created bitmap is not frozen';
    ok !$rb->readonly, 'read-write handle is not read-only';

    $rb->add_many([@dense]);
    $rb->add($_) for @sparse;
    $rb->add_many([@run]);

    is $rb->cardinality, $card, 'producer cardinality correct';
    is $rb->stats->{buckets_used}, 3, 'three non-empty buckets (2 array + 1 bitmap)';
    ok $rb->cardinality > 4096, 'dense bucket exceeds array cap -> a bitmap container exists';

    $rb->freeze;
    ok $rb->frozen,   'frozen after ->freeze';
    ok $rb->readonly, 'freezing handle becomes read-only';
    is $rb->cardinality, $card, 'cardinality unchanged by freeze';

    like exception(sub { $rb->add(1) }),          qr/frozen|read-only/, 'add on frozen handle croaks';
    like exception(sub { $rb->set(1) }),          qr/frozen|read-only/, 'set (alias) on frozen handle croaks';
    like exception(sub { $rb->add_many([1]) }),   qr/frozen|read-only/, 'add_many on frozen handle croaks';
    like exception(sub { $rb->remove(0) }),       qr/frozen|read-only/, 'remove on frozen handle croaks';
    like exception(sub { $rb->delete(0) }),       qr/frozen|read-only/, 'delete (alias) on frozen handle croaks';
    like exception(sub { $rb->clear }),           qr/frozen|read-only/, 'clear on frozen handle croaks';
    {
        my $other = Data::RoaringBitmap::Shared->new(undef, 256);
        $other->add(42);
        like exception(sub { $rb->union($other) }),     qr/frozen|read-only/, 'union on frozen handle croaks';
        like exception(sub { $rb->intersect($other) }), qr/frozen|read-only/, 'intersect on frozen handle croaks';
    }
    like exception(sub { $rb->freeze }),          qr/read-only/,        'freeze on a read-only handle croaks';
}

# ---- consumer: read-only attach (the shipped artifact) ----
# Every read/query/accessor below runs on a PROT_READ mapping. A method that
# still takes the rwlock -- or that normalizes/caches into the mapping -- would
# SIGSEGV here.  Reaching done_testing is itself the SIGSEGV proof.
{
    my $ro = Data::RoaringBitmap::Shared->new_readonly($path);
    isa_ok $ro, 'Data::RoaringBitmap::Shared';
    ok $ro->frozen,   'read-only view reports frozen';
    ok $ro->readonly, 'read-only view reports readonly';

    # contains across BOTH container kinds (bitmap bucket 0, array buckets 5 & 10)
    ok  $ro->contains(0),        'contains(min, bitmap container) via read-only view';
    ok  $ro->contains(2500),     'contains(mid dense, bitmap container) via read-only view';
    ok  $ro->contains(5000),     'contains(top dense, bitmap container) via read-only view';
    ok  $ro->contains($B5 | 1),  'contains(sparse, array container) via read-only view';
    ok  $ro->contains($B5 | 40000), 'contains(sparse high, array container) via read-only view';
    ok  $ro->contains($B10 | 100),  'contains(run start, array container) via read-only view';
    ok  $ro->contains($max),     'contains(max, array container) via read-only view';
    ok  $ro->test($B5 | 1000),   'test (alias) via read-only view';
    ok !$ro->contains($_), "absent $_ false via read-only view" for @absent;

    is $ro->cardinality, $card, 'cardinality lock-free matches producer';
    is $ro->count,       $card, 'count (alias) lock-free';
    is $ro->size,        $card, 'size (alias) lock-free';
    ok !$ro->is_empty,          'is_empty false lock-free';
    is $ro->min, $min, 'min (scans bitmap container) lock-free matches producer';
    is $ro->max, $max, 'max (scans array container) lock-free matches producer';

    my $list = $ro->to_array;
    is scalar(@$list), $card, 'to_array length matches cardinality lock-free';
    is $list->[0],      $min,  'to_array first element is the min';
    is $list->[-1],     $max,  'to_array last element is the max';
    is_deeply $list, [ sort { $a <=> $b } @all ], 'to_array contents exactly match producer, ascending';

    my $st = $ro->stats;
    is $st->{frozen},       1,     'stats.frozen set';
    is $st->{readonly},     1,     'stats.readonly set';
    is $st->{cardinality},  $card, 'stats.cardinality lock-free';
    is $st->{buckets_used}, 3,     'stats.buckets_used lock-free';
    ok $st->{mmap_size} > 0,       'stats geometry present read-only';

    is $ro->path, $path, 'path readable read-only';
    is $ro->memfd, -1,   'memfd readable read-only (file-backed => -1)';
    eval { $ro->sync };
    ok !$@, 'sync on read-only view is a silent no-op';

    like exception(sub { $ro->add(1) }),          qr/read-only/, 'add on read-only view croaks';
    like exception(sub { $ro->add_many([1]) }),   qr/read-only/, 'add_many on read-only view croaks';
    like exception(sub { $ro->remove(0) }),       qr/read-only/, 'remove on read-only view croaks';
    like exception(sub { $ro->clear }),           qr/read-only/, 'clear on read-only view croaks';
    like exception(sub { $ro->freeze }),          qr/read-only/, 'freeze on read-only view croaks';
    {
        my $m = Data::RoaringBitmap::Shared->new(undef, 256);
        $m->add(1);
        like exception(sub { $ro->union($m) }),     qr/read-only/, 'union on read-only view croaks';
        like exception(sub { $ro->intersect($m) }), qr/read-only/, 'intersect on read-only view croaks';
    }
}

# ---- two independent read-only views of the same file, concurrently ----
{
    my $a = Data::RoaringBitmap::Shared->new_readonly($path);
    my $b = Data::RoaringBitmap::Shared->new_readonly($path);
    ok $a->contains(2500) && $b->contains(2500),
       'two read-only views query the same file (bitmap container)';
    ok $a->contains($B5 | 1) && $b->contains($B5 | 1),
       'two read-only views query the same file (array container)';
}

# ---- refuse a read-write reopen of a sealed file ----
like exception(sub { Data::RoaringBitmap::Shared->new($path, 256) }),
     qr/frozen|read-only/, 'read-write reopen of a sealed file is refused';

# ---- new_readonly rejects a non-frozen file ----
{
    my $u = "$dir/unsealed.rb";
    { my $rb = Data::RoaringBitmap::Shared->new($u, 256); $rb->add(7); }
    like exception(sub { Data::RoaringBitmap::Shared->new_readonly($u) }),
         qr/not frozen/, 'new_readonly on an unsealed file croaks';
}

# ---- new_readonly error paths ----
like exception(sub { Data::RoaringBitmap::Shared->new_readonly("$dir/does-not-exist.rb") }),
     qr/open|No such/, 'new_readonly on a missing path croaks';
like exception(sub { Data::RoaringBitmap::Shared->new_readonly(undef) }),
     qr/required/, 'new_readonly requires a path';

# ---- union FROM a frozen (read-only) other into a mutable bitmap (lock-free o read) ----
# Exercises copying an array container AND OR-ing a bitmap container out of a
# PROT_READ mapping while only the receiver is write-locked.
{
    my $m   = "$dir/other.rb";
    my $B   = Data::RoaringBitmap::Shared->new($m, 256);
    $B->add_many([@dense]);       # bucket 0 -> bitmap container
    $B->add($_) for @sparse;      # bucket 5 -> array container
    $B->freeze;
    my $Bro = Data::RoaringBitmap::Shared->new_readonly($m);

    my $A = Data::RoaringBitmap::Shared->new(undef, 256);
    $A->add(10);                  # bucket 0 (array) -- overlaps Bro's dense bitmap
    $A->add($B10 | 100);          # bucket 10 (array) -- absent from Bro
    my $ret = $A->union($Bro);    # must read Bro's containers without locking its PROT_READ map
    is $ret, $A, 'union returns the receiver for chaining';

    ok $A->contains(10),          'union target keeps its own array member';
    ok $A->contains($B10 | 100),  'union target keeps its own bucket Bro lacks';
    ok $A->contains(0),           'union pulled in Bro min (bitmap container)';
    ok $A->contains(5000),        'union pulled in Bro dense top (bitmap container)';
    ok $A->contains($B5 | 40000), 'union pulled in Bro sparse (array container)';
    is $A->cardinality, scalar(keys %{{ map { $_ => 1 } (10, $B10|100, @dense, @sparse) }}),
       'union cardinality is the set union of both';

    # ---- intersect FROM a frozen (read-only) other ----
    my $E = Data::RoaringBitmap::Shared->new(undef, 256);
    $E->add_many([0 .. 3000]);    # bucket 0 array, overlaps Bro's bitmap
    $E->add($B5 | 1);             # bucket 5 array, in Bro
    $E->add(900000);              # bucket 13, absent from Bro -> dropped
    $E->intersect($Bro);          # array(E) & bitmap(Bro), array & array, drop-missing-bucket
    ok  $E->contains(0),          'intersect kept a shared bitmap-side member';
    ok  $E->contains(3000),       'intersect kept the shared dense top';
    ok  $E->contains($B5 | 1),    'intersect kept a shared array member';
    ok !$E->contains(900000),     'intersect dropped a member absent from the frozen other';
    ok !$E->contains(4000),       'intersect dropped a member above the overlap';
    is $E->cardinality, 3002,     'intersect cardinality = |0..3000| + 1 shared array member';
}

done_testing;

# minimal exception helper (avoid a Test::Fatal dependency)
sub exception {
    my $code = shift;
    my $err;
    { local $@; eval { $code->(); 1 } or $err = $@; }
    return $err;
}
