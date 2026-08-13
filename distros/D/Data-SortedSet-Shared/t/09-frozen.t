use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::SortedSet::Shared;

# Frozen (read-only) mode: a producer builds a multi-level B+tree and freezes it;
# consumers open it O_RDONLY / PROT_READ and query it lock-free.  Every read --
# especially a FULL range / range_by_score / each iteration -- must run on the
# PROT_READ mapping without writing a byte (a stray write SIGSEGVs the mmap).

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/frozen.sset";
my $N    = 1000;                      # >> SS_ORDER(16): forces internal nodes

# expected: member i carries score i+0.5, so (score,member) order == member order
my @members = (1 .. $N);

# ---- producer: build a multi-level tree, then freeze ----
{
    my $z = Data::SortedSet::Shared->new($path, 2 * $N);
    ok !$z->frozen,   'freshly created set is not frozen';
    ok !$z->readonly, 'read-write handle is not read-only';

    $z->add($_, $_ + 0.5) for 1 .. ($N - 3);
    $z->add_many([ map { [ $_, $_ + 0.5 ] } ($N - 2) .. $N ]);
    is $z->count, $N, 'producer holds all members';
    ok $z->stats->{height} >= 2, 'multi-level B+tree (internal nodes present)';
    ok $z->_validate, 'producer tree structurally valid';

    $z->freeze;
    ok $z->frozen,   'frozen after ->freeze';
    ok $z->readonly, 'freezing handle becomes read-only';
    is $z->count, $N, 'count unchanged by freeze';

    # every mutator croaks on the (now sealed) producer handle
    like exception(sub { $z->add(1, 2) }),         qr/frozen|read-only/, 'add croaks when frozen';
    like exception(sub { $z->incr(1, 1) }),        qr/frozen|read-only/, 'incr croaks when frozen';
    like exception(sub { $z->remove(1) }),         qr/frozen|read-only/, 'remove croaks when frozen';
    like exception(sub { $z->clear }),             qr/frozen|read-only/, 'clear croaks when frozen';
    like exception(sub { $z->pop_min }),           qr/frozen|read-only/, 'pop_min croaks when frozen';
    like exception(sub { $z->pop_max }),           qr/frozen|read-only/, 'pop_max croaks when frozen';
    like exception(sub { $z->add_many([[1,2]]) }), qr/frozen|read-only/, 'add_many croaks when frozen';
    like exception(sub { $z->freeze }),            qr/read-only/,        'freeze on a read-only handle croaks';
}

# ---- consumer: read-only PROT_READ attach (the shipped artifact) ----
{
    my $ro = Data::SortedSet::Shared->new_readonly($path);
    isa_ok $ro, 'Data::SortedSet::Shared';
    ok $ro->frozen,   'read-only view reports frozen';
    ok $ro->readonly, 'read-only view reports readonly';
    is $ro->count,       $N,     'count (lock-free)';
    is $ro->max_entries, 2 * $N, 'max_entries (lock-free)';

    # --- point reads, lock-free, must match the producer ---
    cmp_ok $ro->score(1),  '==', 1.5,      'score(1)';
    cmp_ok $ro->score($N), '==', $N + 0.5, 'score(N)';
    ok  $ro->exists(500),  'exists present';
    ok !$ro->exists(-42),  'exists absent';
    is $ro->score(-42), undef, 'score of absent member is undef';

    is $ro->rank(1),     0,      'rank(1) == 0';
    is $ro->rank($N),    $N - 1, 'rank(N) == N-1';
    is $ro->rev_rank(1), $N - 1, 'rev_rank(1) == N-1';
    is $ro->rank(500),   499,    'rank(500)';

    is $ro->at_rank(0),  1,  'at_rank(0)';
    is $ro->at_rank(-1), $N, 'at_rank(-1)';
    is $ro->at_rank(499), 500, 'at_rank(499)';

    is $ro->count_in_score(100.0, 200.0), 100, 'count_in_score window';   # members 100..199
    is $ro->count_in_score(0, $N + 1),    $N,  'count_in_score all';

    # --- peek ---
    is_deeply [ $ro->peek_min ], [ 1,  1.5      ], 'peek_min';
    is_deeply [ $ro->peek_max ], [ $N, $N + 0.5 ], 'peek_max';

    # --- FULL range iteration on the PROT_READ handle ---
    # (a shared-cursor / augmentation write on the read path would SIGSEGV here)
    my @all = $ro->range_by_rank(0, -1);
    is scalar(@all), $N, 'range_by_rank(0,-1) full length';
    is_deeply \@all, \@members, 'range_by_rank(0,-1) exact order';

    my @all_ws = $ro->range_by_rank(0, -1, withscores => 1);
    is scalar(@all_ws), 2 * $N, 'range_by_rank withscores length';
    cmp_ok $all_ws[0], '==', 1,   'withscores first member';
    cmp_ok $all_ws[1], '==', 1.5, 'withscores first score';

    my @rev = $ro->rev_range_by_rank(0, -1);
    is_deeply \@rev, [ reverse @members ], 'rev_range_by_rank(0,-1) exact order';

    # --- FULL range_by_score iteration on the PROT_READ handle ---
    my @by_score = $ro->range_by_score(0, $N + 1);
    is scalar(@by_score), $N, 'range_by_score(all) full length';
    is_deeply \@by_score, \@members, 'range_by_score(all) exact order';

    my @win = $ro->range_by_score(100.0, 200.0);
    is_deeply \@win, [ 100 .. 199 ], 'range_by_score window exact';

    my @rev_score = $ro->rev_range_by_score($N + 1, 0);
    is_deeply \@rev_score, [ reverse @members ], 'rev_range_by_score(all) exact order';

    # --- each(): full callback iteration over the lock-free snapshot ---
    my @seen;
    $ro->each(sub { push @seen, $_[0] });
    is_deeply \@seen, \@members, 'each() full iteration on PROT_READ handle';

    ok $ro->_validate, 'read-only tree validates lock-free';

    my $st = $ro->stats;
    is $st->{frozen},   1,  'stats.frozen == 1';
    is $st->{readonly}, 1,  'stats.readonly == 1';
    is $st->{count},    $N, 'stats.count via read-only view';

    # every mutator croaks on the read-only view
    like exception(sub { $ro->add(1, 2) }),         qr/read-only|frozen/, 'add croaks on read-only view';
    like exception(sub { $ro->incr(1, 1) }),        qr/read-only|frozen/, 'incr croaks on read-only view';
    like exception(sub { $ro->remove(1) }),         qr/read-only|frozen/, 'remove croaks on read-only view';
    like exception(sub { $ro->clear }),             qr/read-only|frozen/, 'clear croaks on read-only view';
    like exception(sub { $ro->pop_min }),           qr/read-only|frozen/, 'pop_min croaks on read-only view';
    like exception(sub { $ro->pop_max }),           qr/read-only|frozen/, 'pop_max croaks on read-only view';
    like exception(sub { $ro->add_many([[1,2]]) }), qr/read-only|frozen/, 'add_many croaks on read-only view';
    like exception(sub { $ro->freeze }),            qr/read-only/,        'freeze croaks on read-only view';

    is $ro->sync, undef, 'sync is a harmless no-op on a read-only view';
}

# ---- two independent read-only views of the same file, concurrently ----
{
    my $a = Data::SortedSet::Shared->new_readonly($path);
    my $b = Data::SortedSet::Shared->new_readonly($path);
    ok $a->score(1) == 1.5 && $b->score($N) == $N + 0.5,
        'two read-only views query the same file';
}

# ---- refuse a read-write reopen of a sealed file ----
like exception(sub { Data::SortedSet::Shared->new($path, 2 * $N) }),
     qr/frozen|read-only/, 'read-write reopen of a sealed file is refused';

# ---- refuse a read-write new_from_fd of a sealed file ----
{
    open my $fh, '+<', $path or die "open $path: $!";
    like exception(sub { Data::SortedSet::Shared->new_from_fd(fileno $fh) }),
         qr/frozen|read-only/, 'new_from_fd on a sealed file is refused';
    close $fh;
}

# ---- new_readonly rejects a non-frozen file ----
{
    my $u = "$dir/unsealed.sset";
    { my $z = Data::SortedSet::Shared->new($u, 100); $z->add(1, 1); }
    like exception(sub { Data::SortedSet::Shared->new_readonly($u) }),
         qr/not frozen/, 'new_readonly on an unsealed file croaks';
}

# ---- new_readonly error paths ----
like exception(sub { Data::SortedSet::Shared->new_readonly("$dir/does-not-exist.sset") }),
     qr/open|No such/, 'new_readonly on a missing path croaks';
like exception(sub { Data::SortedSet::Shared->new_readonly(undef) }),
     qr/required/, 'new_readonly requires a path';

done_testing;

# minimal exception helper (avoid a Test::Fatal dependency)
sub exception {
    my $code = shift;
    my $err;
    { local $@; eval { $code->(); 1 } or $err = $@; }
    return $err;
}
