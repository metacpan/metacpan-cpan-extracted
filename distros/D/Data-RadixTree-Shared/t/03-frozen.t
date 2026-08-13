use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::RadixTree::Shared;

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/frozen.rdx";

# Key set with shared prefixes: foo/foobar/fo/fox forces edge splits (as in
# t/01-basic.t), 10/10.0/10.0.0 forces a longest-prefix chain, and
# alpha/beta/gamma add extra root branches -- together a genuine multi-level
# tree, not a single flat leaf.
my %kv = (
    foo      => 1,
    foobar   => 2,
    fo       => 3,
    fox      => 4,
    "10"     => 100,
    "10.0"   => 200,
    "10.0.0" => 300,
    alpha    => 10,
    beta     => 20,
    gamma    => 30,
);
my $nkeys = scalar keys %kv;

# ---- producer: build (forcing splits), freeze ----
{
    my $t = Data::RadixTree::Shared->new($path, 4096, 65536);
    ok !$t->frozen,   'freshly created tree is not frozen';
    ok !$t->readonly, 'read-write handle is not read-only';
    $t->insert($_, $kv{$_}) for sort keys %kv;
    my $c = $t->count;
    is $c, $nkeys, 'producer inserted every key (splits happened along the way)';

    $t->freeze;
    ok $t->frozen,   'frozen after ->freeze';
    ok $t->readonly, 'freezing handle becomes read-only';
    is $t->count, $c, 'count unchanged by freeze';

    like exception(sub { $t->insert("new-key", 1) }), qr/frozen|read-only/, 'insert on frozen handle croaks';
    like exception(sub { $t->delete("foo") }),        qr/frozen|read-only/, 'delete on frozen handle croaks';
    like exception(sub { $t->clear }),                qr/frozen|read-only/, 'clear on frozen handle croaks';
    like exception(sub { $t->freeze }),               qr/read-only/,        'freeze on an already-read-only handle croaks';

    # tree is untouched by the attempted (croaking) mutations
    is $t->lookup("foo"), 1, 'foo still queryable after failed mutation attempts';
    is $t->count, $c, 'count unchanged after failed mutation attempts';
}

# ---- consumer: read-only attach (the shipped artifact) ----
{
    my $ro = Data::RadixTree::Shared->new_readonly($path);
    isa_ok $ro, 'Data::RadixTree::Shared';
    ok $ro->frozen,   'read-only view reports frozen';
    ok $ro->readonly, 'read-only view reports readonly';

    # every read method, over every key, on the read-only (PROT_READ) handle --
    # a method that still took the rwlock here would SIGSEGV (writing to a
    # read-only mapping). This also walks every level of the split tree built
    # above, which is where a hidden write (e.g. lazy compression) would hide.
    for my $k (sort keys %kv) {
        is $ro->lookup($k),   $kv{$k}, "lookup('$k') matches producer via read-only view";
        is $ro->get($k),      $kv{$k}, "get('$k') matches producer via read-only view (alias)";
        ok $ro->exists($k),            "exists('$k') true via read-only view";
        ok $ro->contains($k),          "contains('$k') true via read-only view (alias)";
    }
    ok !$ro->exists("never-added-xyz"), 'absent key false via read-only view';
    ok !defined($ro->lookup("never-added-xyz")), 'absent key lookup undef via read-only view';
    ok !$ro->exists("f"), '!exists intermediate non-key "f" via read-only view';
    ok !$ro->exists("foob"), '!exists intermediate non-key "foob" via read-only view';

    # longest_prefix walks multiple tree levels read-only; values must match
    # what the producer computed before freezing.
    is $ro->longest_prefix("10.0.0.5"), 300, 'longest_prefix full chain via read-only view';
    is $ro->longest_prefix("10.0.9"),   200, 'longest_prefix backs off to "10.0" via read-only view';
    is $ro->longest_prefix("10.5"),     100, 'longest_prefix backs off to "10" via read-only view';
    is $ro->longest_prefix("foobarx"),    2, 'longest_prefix over a split edge via read-only view';
    is $ro->longest_prefix("foo"),        1, 'longest_prefix exact match via read-only view';
    ok !defined($ro->longest_prefix("zzz")), 'longest_prefix with no stored prefix is undef via read-only view';

    is $ro->count, $nkeys, 'count works read-only (lock-free)';
    is $ro->size,  $nkeys, 'size alias works read-only';

    my $st = $ro->stats;
    is ref($st), 'HASH', 'stats returns a hashref read-only';
    is $st->{frozen},   1, 'stats.frozen set';
    is $st->{readonly}, 1, 'stats.readonly set';
    is $st->{keys}, $nkeys, 'stats.keys matches read-only';
    cmp_ok $st->{nodes_capacity}, '>=', 2, 'stats nodes_capacity present read-only';
    cmp_ok $st->{nodes_used}, '<=', $st->{nodes_capacity}, 'stats nodes_used within capacity read-only';
    cmp_ok $st->{arena_capacity}, '>=', 1, 'stats arena_capacity present read-only';
    cmp_ok $st->{arena_used}, '<=', $st->{arena_capacity}, 'stats arena_used within capacity read-only';

    is $ro->path, $path, 'path readable read-only';
    is $ro->memfd, -1, 'memfd readable read-only (file-backed => -1)';
    eval { $ro->sync };
    ok !$@, 'sync on read-only view is a silent no-op';

    like exception(sub { $ro->insert("new-key", 1) }), qr/read-only/, 'insert on read-only view croaks';
    like exception(sub { $ro->delete("foo") }),        qr/read-only/, 'delete on read-only view croaks';
    like exception(sub { $ro->clear }),                qr/read-only/, 'clear on read-only view croaks';
    like exception(sub { $ro->freeze }),               qr/read-only/, 'freeze on read-only view croaks';
}

# ---- two independent read-only views of the same file, concurrently ----
{
    my $a = Data::RadixTree::Shared->new_readonly($path);
    my $b = Data::RadixTree::Shared->new_readonly($path);
    ok $a->lookup("foo") && $b->lookup("foo"), 'two read-only views query the same file';
    is $a->longest_prefix("10.0.0.9"), $b->longest_prefix("10.0.0.9"),
        'two read-only views agree on longest_prefix';
}

# ---- refuse a read-write reopen of a sealed file ----
like exception(sub { Data::RadixTree::Shared->new($path, 4096, 65536) }),
     qr/frozen|read-only/, 'read-write reopen of a sealed file is refused';

# ---- new_readonly rejects a non-frozen file ----
{
    my $u = "$dir/unsealed.rdx";
    { my $t = Data::RadixTree::Shared->new($u, 4096, 65536); $t->insert("q", 1); }
    like exception(sub { Data::RadixTree::Shared->new_readonly($u) }),
         qr/not frozen/, 'new_readonly on an unsealed file croaks';
}

# ---- new_readonly error paths ----
like exception(sub { Data::RadixTree::Shared->new_readonly("$dir/does-not-exist.rdx") }),
     qr/open|No such/, 'new_readonly on a missing path croaks';
like exception(sub { Data::RadixTree::Shared->new_readonly(undef) }),
     qr/required/, 'new_readonly requires a path';

done_testing;

# minimal exception helper (avoid a Test::Fatal dependency)
sub exception {
    my $code = shift;
    my $err;
    { local $@; eval { $code->(); 1 } or $err = $@; }
    return $err;
}
