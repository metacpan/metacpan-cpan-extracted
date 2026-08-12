use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Intern::Shared;

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/frozen.intern";

# plain words plus byte-accuracy edge cases (empty, embedded NUL, high bytes)
my @words = (map { "word$_" } 1 .. 50);
push @words, "", "a\0b\0c", "\xff\x00\xfe";

my (%exp_id, @exp_str, $exp_count, $exp_arena_used);

# ---- producer: build, populate, freeze ----
{
    my $in = Data::Intern::Shared->new($path, 100, 4096);
    ok !$in->frozen,   'freshly created table is not frozen';
    ok !$in->readonly, 'read-write handle is not read-only';

    for my $w (@words) {
        my $id = $in->intern($w);
        ok defined($id), "intern(" . length($w) . "-byte str) succeeded" or next;
        $exp_id{$w}   = $id;
        $exp_str[$id] = $w;
    }
    $exp_count      = $in->count;
    $exp_arena_used = $in->arena_used;
    is $exp_count, scalar(@words), 'all distinct words interned';

    $in->freeze;
    ok $in->frozen,   'frozen after ->freeze';
    ok $in->readonly, 'freezing handle becomes read-only';
    is $in->count,      $exp_count,      'count unchanged by freeze';
    is $in->arena_used, $exp_arena_used, 'arena_used unchanged by freeze';

    like exception(sub { $in->intern("new-string") }), qr/frozen|read-only/, 'intern on frozen handle croaks';
    like exception(sub { $in->clear }),                qr/frozen|read-only/, 'clear on frozen handle croaks';
    like exception(sub { $in->freeze }),                qr/read-only/,       'freeze on a read-only handle croaks';

    # the frozen handle's own data is untouched by the rejected mutators
    is $in->count, $exp_count, 'count still unchanged after rejected mutators';
}

# ---- consumer: read-only attach (the shipped artifact) ----
{
    my $ro = Data::Intern::Shared->new_readonly($path);
    isa_ok $ro, 'Data::Intern::Shared';
    ok $ro->frozen,   'read-only view reports frozen';
    ok $ro->readonly, 'read-only view reports readonly';

    # every read/query/accessor method, proven lock-free (a missed lock-skip
    # branch SIGSEGVs on this PROT_READ mapping) and matching the producer
    for my $w (@words) {
        is $ro->id_of($w), $exp_id{$w}, "id_of(" . length($w) . "-byte str) matches producer (lock-free)";
        ok $ro->exists($w), "exists(" . length($w) . "-byte str) true via read-only view";
    }
    for my $id (0 .. $#exp_str) {
        is $ro->string($id), $exp_str[$id], "string($id) round-trips via read-only view";
    }
    ok !defined($ro->id_of("--never-interned--")), 'id_of of an absent string is undef read-only';
    ok !$ro->exists("--never-interned--"),         'exists false for an absent string read-only';
    ok !defined($ro->string($exp_count)),          'string of an out-of-range id is undef read-only';
    ok !defined($ro->string($exp_count + 1000)),   'string far out of range is undef read-only';

    is $ro->count,       $exp_count,      'count matches producer (lock-free)';
    is $ro->arena_used,  $exp_arena_used, 'arena_used matches producer (lock-free)';
    is $ro->max_strings, 100,             'max_strings works read-only';
    is $ro->arena_bytes, 4096,            'arena_bytes works read-only';
    is $ro->path,        $path,           'path works read-only';
    is $ro->memfd,       -1,              'memfd works read-only (file-backed => -1)';

    my $st = $ro->stats;
    is ref($st), 'HASH',              'stats works read-only';
    is $st->{frozen},     1,          'stats.frozen set';
    is $st->{readonly},   1,          'stats.readonly set';
    is $st->{count},      $exp_count, 'stats.count matches producer';
    is $st->{arena_used}, $exp_arena_used, 'stats.arena_used matches producer';
    is $st->{max_strings}, 100,       'stats.max_strings';
    is $st->{arena_bytes}, 4096,      'stats.arena_bytes';
    cmp_ok $st->{hash_slots}, '>', 100, 'stats.hash_slots > max_strings';
    cmp_ok $st->{mmap_size}, '>', 0,    'stats.mmap_size';

    ok eval { $ro->sync; 1 }, 'sync is a silent no-op on a read-only handle'
        or diag $@;

    like exception(sub { $ro->intern("x") }), qr/read-only/, 'intern on read-only view croaks';
    like exception(sub { $ro->clear }),       qr/read-only/, 'clear on read-only view croaks';
    like exception(sub { $ro->freeze }),      qr/read-only/, 'freeze on read-only view croaks';

    # the read-only handle's data is untouched by the rejected mutators
    is $ro->count, $exp_count, 'count still unchanged after rejected mutators on read-only view';
}

# ---- two independent read-only views of the same file, concurrently ----
{
    my $a = Data::Intern::Shared->new_readonly($path);
    my $b = Data::Intern::Shared->new_readonly($path);
    is $a->id_of("word1"), $b->id_of("word1"), 'two read-only views agree on the same file';
    is $a->string($b->id_of("word2")), "word2", 'cross-view id/string round-trip';
}

# ---- refuse a read-write reopen of a sealed file ----
like exception(sub { Data::Intern::Shared->new($path, 100, 4096) }),
     qr/frozen|read-only/, 'read-write reopen of a sealed file is refused';

# ---- new_from_fd also refuses a sealed file ----
{
    open my $fh, '+<', $path or die "open $path: $!";
    like exception(sub { Data::Intern::Shared->new_from_fd(fileno($fh)) }),
         qr/frozen|read-only/, 'new_from_fd on a sealed file is refused';
}

# ---- new_readonly rejects a non-frozen file ----
{
    my $u = "$dir/unsealed.intern";
    { my $in = Data::Intern::Shared->new($u, 50); $in->intern("q"); }
    like exception(sub { Data::Intern::Shared->new_readonly($u) }),
         qr/not frozen/, 'new_readonly on an unsealed file croaks';
}

# ---- new_readonly error paths ----
like exception(sub { Data::Intern::Shared->new_readonly("$dir/does-not-exist.intern") }),
     qr/open|No such/, 'new_readonly on a missing path croaks';
like exception(sub { Data::Intern::Shared->new_readonly(undef) }),
     qr/required/, 'new_readonly requires a path';

# ---- post-wrlock seal re-check: a second, already-open read-write handle on
# the same file has its OWN local readonly flag still 0 (it did not call
# freeze itself), so it can only be caught by the hdr->sealed check taken
# after the write lock is acquired -- not the h->readonly fast-path. ----
{
    my $u2 = "$dir/race.intern";
    my $w1 = Data::Intern::Shared->new($u2, 50);
    my $w2 = Data::Intern::Shared->new($u2, 50);   # second independent handle, same file
    $w1->intern("pre-freeze");
    $w1->freeze;                                    # only $w1's local readonly flag is set
    ok !$w2->readonly, 'a second handle opened earlier does not locally know it is frozen';
    like exception(sub { $w2->intern("post-freeze") }), qr/frozen|read-only/,
         'a second handle still rejects mutation via the post-wrlock sealed re-check';
    like exception(sub { $w2->clear }), qr/frozen|read-only/,
         'clear on a second handle also rejects via the post-wrlock sealed re-check';
}

# ---- freeze also works for anonymous tables (no path, nothing to msync) ----
{
    my $anon = Data::Intern::Shared->new(undef, 50);
    my $id = $anon->intern("anon-str");
    $anon->freeze;
    ok $anon->frozen,   'anonymous table can be frozen';
    ok $anon->readonly, 'freezing an anonymous handle makes it read-only';
    is $anon->string($id), "anon-str",       'anonymous frozen table still queryable (string)';
    is $anon->id_of("anon-str"), $id,        'anonymous frozen table still queryable (id_of)';
    ok $anon->exists("anon-str"),            'anonymous frozen table still queryable (exists)';
    like exception(sub { $anon->intern("more") }), qr/read-only/, 'mutating a frozen anonymous table croaks';
}

done_testing;

# minimal exception helper (avoid a Test::Fatal dependency)
sub exception {
    my $code = shift;
    my $err;
    { local $@; eval { $code->(); 1 } or $err = $@; }
    return $err;
}
