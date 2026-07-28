use strict;
use warnings;
use Test::More;
use Data::RadixTree::Shared;

# ---- constructor + initial state ----
{
    my $t = Data::RadixTree::Shared->new(undef, 4096, 65536);
    isa_ok $t, 'Data::RadixTree::Shared';
    ok !defined($t->path), 'anonymous path is undef';
    is $t->count, 0, 'fresh tree has count 0';
    is $t->size, 0, 'size is an alias for count';
    ok !$t->exists("anything"), 'nothing exists in a fresh tree';
    ok !defined($t->lookup("anything")), 'lookup of absent key is undef';
}

# ---- basic insert / lookup / exists ----
{
    my $t = Data::RadixTree::Shared->new(undef, 4096, 65536);
    is $t->insert("foo", 1), 1, 'insert("foo",1) returns 1 (new)';
    is $t->insert("foo", 1), 0, 'insert("foo",1) again returns 0 (update)';
    is $t->lookup("foo"), 1, 'lookup("foo") == 1';
    is $t->get("foo"), 1, 'get is an alias for lookup';
    ok $t->exists("foo"), 'exists("foo")';
    ok $t->contains("foo"), 'contains is an alias for exists';
    ok !$t->exists("fo"), '!exists("fo") -- a proper prefix is not a stored key';
    ok !$t->exists("foox"), '!exists("foox") -- a longer string is not stored';

    # update changes the value but not the count
    is $t->insert("foo", 42), 0, 're-insert returns 0';
    is $t->lookup("foo"), 42, 'value updated to 42';
    is $t->count, 1, 'count still 1 after update';
}

{   # value 0 is a valid stored value, distinguishable from not-found
    my $t0 = Data::RadixTree::Shared->new(undef, 4096, 65536);
    is $t0->insert("z", 0), 1, 'insert(key, 0) returns 1 (new)';
    ok defined($t0->lookup("z")), 'lookup of value-0 key is defined (not undef)';
    is $t0->lookup("z"), 0, 'lookup of value-0 key returns 0';
    ok $t0->exists("z"), 'exists true for value-0 key';
    ok !defined($t0->lookup("absent")), 'absent key returns undef, distinct from a stored 0';
}

# ---- edge split: an order that forces splits ----
{
    my $t = Data::RadixTree::Shared->new(undef, 4096, 65536);
    # insert "foo" first (a single leaf "foo"), then "foobar" (descend+extend),
    # then "fo" (split "foo" -> mid "fo" + leaf "o"), then "fox" (split under "fo").
    is $t->insert("foo",    10), 1, 'insert foo';
    is $t->insert("foobar", 20), 1, 'insert foobar (extends foo)';
    is $t->insert("fo",     30), 1, 'insert fo (splits the foo edge)';
    is $t->insert("fox",    40), 1, 'insert fox (branches under fo)';

    is $t->lookup("foo"),    10, 'lookup foo after splits';
    is $t->lookup("foobar"), 20, 'lookup foobar after splits';
    is $t->lookup("fo"),     30, 'lookup fo after splits';
    is $t->lookup("fox"),    40, 'lookup fox after splits';
    is $t->count, 4, 'four distinct keys';

    ok !$t->exists("f"),      '!exists f (intermediate, not stored)';
    ok !$t->exists("fob"),    '!exists fob';
    ok !$t->exists("foob"),   '!exists foob';
    ok !$t->exists("fooba"),  '!exists fooba';
    ok !$t->exists("foobarx"),'!exists foobarx';
}

# ---- another split set: a, ab, abc, abd, b ----
{
    my $t = Data::RadixTree::Shared->new(undef, 4096, 65536);
    my %v = (a => 1, ab => 2, abc => 3, abd => 4, b => 5);
    is $t->insert($_, $v{$_}), 1, "insert $_" for qw(a ab abc abd b);
    is $t->lookup($_), $v{$_}, "lookup $_" for sort keys %v;
    is $t->count, 5, 'five distinct keys';
    ok !$t->exists("ac"), '!exists ac';
    ok !$t->exists("abcd"), '!exists abcd';
    ok !$t->exists(""), 'empty key not present (never inserted)';
}

# ---- longest_prefix ----
{
    my $t = Data::RadixTree::Shared->new(undef, 4096, 65536);
    $t->insert("10",     100);
    $t->insert("10.0",   200);
    $t->insert("10.0.0", 300);

    is $t->longest_prefix("10.0.0.5"), 300, 'longest_prefix returns value of "10.0.0"';
    is $t->longest_prefix("10.0.0"),   300, 'exact match is the longest prefix';
    is $t->longest_prefix("10.0.9"),   200, 'longest_prefix backs off to "10.0"';
    is $t->longest_prefix("10.5"),     100, 'longest_prefix backs off to "10"';
    is $t->longest_prefix("10"),       100, 'exact "10" matches';
    ok !defined($t->longest_prefix("9")),  'longest_prefix("9") is undef (no prefix stored)';
    ok !defined($t->longest_prefix("1")),  'longest_prefix("1") is undef ("10" is not a prefix of "1")';

    # empty-key insert: the empty string is a prefix of everything
    is $t->insert("", 7), 1, 'insert empty key';
    is $t->longest_prefix("9"), 7, 'empty key is the longest prefix when nothing else matches';
    is $t->longest_prefix("zzz"), 7, 'empty key matches an arbitrary query';
    is $t->longest_prefix("10.0.0.5"), 300, 'a more specific key still wins over the empty key';
    is $t->lookup(""), 7, 'lookup of the empty key';
    ok $t->exists(""), 'empty key exists after insert';
}

# ---- delete ----
{
    my $t = Data::RadixTree::Shared->new(undef, 4096, 65536);
    $t->insert($_, length $_) for qw(foo foobar fo fox);
    is $t->count, 4, 'four keys before delete';

    is $t->delete("foo"), 1, 'delete("foo") returns 1';
    ok !$t->exists("foo"), '!exists("foo") after delete';
    ok !defined($t->lookup("foo")), 'lookup("foo") is undef after delete';
    is $t->count, 3, 'count dropped to 3';

    # other keys (including those sharing foo's path) still resolve
    is $t->lookup("foobar"), 6, 'foobar still present (shares deleted prefix path)';
    is $t->lookup("fo"), 2, 'fo still present';
    is $t->lookup("fox"), 3, 'fox still present';

    is $t->delete("foo"), 0, 'delete absent key returns 0';
    is $t->delete("nope"), 0, 'delete never-present key returns 0';
    is $t->count, 3, 'count unchanged after no-op deletes';

    # remove is an alias
    is $t->remove("fox"), 1, 'remove is an alias for delete';
    ok !$t->exists("fox"), '!exists fox after remove';
    is $t->count, 2, 'count == 2';

    # re-insert a deleted key works
    is $t->insert("foo", 99), 1, 're-insert a deleted key returns 1 (new again)';
    is $t->lookup("foo"), 99, 're-inserted value';
    is $t->count, 3, 'count back to 3';
}

# ---- clear ----
{
    my $t = Data::RadixTree::Shared->new(undef, 4096, 65536);
    $t->insert($_, 1) for qw(alpha beta gamma a ab abc);
    cmp_ok $t->count, '>', 0, 'keys before clear';
    $t->clear;
    is $t->count, 0, 'count == 0 after clear';
    ok !$t->exists($_), "!exists $_ after clear" for qw(alpha beta gamma a ab abc);
    ok !defined($t->lookup("alpha")), 'lookup undef after clear';

    # tree is usable again after clear
    is $t->insert("fresh", 5), 1, 'insert after clear works';
    is $t->lookup("fresh"), 5, 'lookup after clear';
    is $t->count, 1, 'count == 1 after re-insert';
}

# ---- count tracks distinct keys ----
{
    my $t = Data::RadixTree::Shared->new(undef, 4096, 65536);
    is $t->count, 0, 'count 0';
    $t->insert("x", 1); is $t->count, 1, 'count 1';
    $t->insert("y", 1); is $t->count, 2, 'count 2';
    $t->insert("x", 9); is $t->count, 2, 'duplicate insert does not raise count';
    $t->delete("x");    is $t->count, 1, 'delete lowers count';
}

# ---- stats keys ----
{
    my $t = Data::RadixTree::Shared->new(undef, 4096, 65536);
    $t->insert("aaa", 1);
    $t->insert("aab", 2);
    my $st = $t->stats;
    is ref($st), 'HASH', 'stats returns a hashref';
    ok exists $st->{$_}, "stats has $_"
        for qw(keys nodes_used nodes_capacity arena_used arena_capacity ops mmap_size);
    is $st->{keys}, 2, 'stats keys == 2';
    is $st->{nodes_capacity}, 4096, 'stats nodes_capacity matches';
    is $st->{arena_capacity}, 65536, 'stats arena_capacity matches';
    cmp_ok $st->{nodes_used}, '>=', 2, 'nodes_used includes NIL + root';
    cmp_ok $st->{nodes_used}, '<=', $st->{nodes_capacity}, 'nodes_used within capacity';
    cmp_ok $st->{arena_used}, '>', 0, 'arena_used > 0 after inserts';
    cmp_ok $st->{arena_used}, '<=', $st->{arena_capacity}, 'arena_used within capacity';
    cmp_ok $st->{ops}, '>', 0, 'ops counted the writes';
    cmp_ok $st->{mmap_size}, '>', 0, 'mmap_size > 0';
}

# ---- error paths ----

# constructor: node_capacity < 2 rejected
ok !eval { Data::RadixTree::Shared->new(undef, 1, 65536); 1 }, 'new(node_cap 1) croaks';
like $@, qr/node_capacity must be/, 'new(node_cap 1) croak mentions node_capacity';
ok !eval { Data::RadixTree::Shared->new_memfd('x', 1, 65536); 1 }, 'new_memfd(node_cap 1) croaks';
like $@, qr/node_capacity must be/, 'new_memfd(node_cap 1) croak mentions node_capacity';

# constructor: arena_capacity 0 rejected
ok !eval { Data::RadixTree::Shared->new(undef, 16, 0); 1 }, 'new(arena_cap 0) croaks';
like $@, qr/arena_capacity must be/, 'new(arena_cap 0) croak mentions arena_capacity';

# constructor: node_capacity above RDX_MAX_NODES (2**24) rejected
ok !eval { Data::RadixTree::Shared->new(undef, 2**24 + 1, 65536); 1 }, 'new(node_cap > max) croaks';
like $@, qr/node_capacity/i, 'oversized node_cap croak mentions node capacity';

# constructor: arena_capacity above RDX_MAX_ARENA (0xF0000000) rejected.
# Validation rejects the size BEFORE any mmap, so this does not try to allocate.
ok !eval { Data::RadixTree::Shared->new(undef, 16, 0xF0000000 + 1); 1 }, 'new(arena_cap > max) croaks';
like $@, qr/arena_capacity/i, 'oversized arena_cap croak mentions arena capacity';

# wide-char key croaks (and BEFORE the lock -- see lock-leak test below)
{
    my $t = Data::RadixTree::Shared->new(undef, 4096, 65536);
    ok !eval { $t->insert("k-\x{2603}", 1); 1 }, 'insert of a wide-char key croaks';
    ok !eval { $t->lookup("q-\x{2603}"); 1 },    'lookup of a wide-char key croaks';
    ok !eval { $t->exists("q-\x{2603}"); 1 },    'exists of a wide-char key croaks';
    ok !eval { $t->longest_prefix("q-\x{2603}"); 1 }, 'longest_prefix of a wide-char key croaks';
    ok !eval { $t->delete("q-\x{2603}"); 1 },    'delete of a wide-char key croaks';
}

# ---- capacity exhaustion: node pool ----
{
    # tiny node pool: NIL + root + a couple. Distinct single-byte keys each need
    # a fresh leaf node, so inserting enough distinct keys must eventually croak.
    # The pre-check prices every insert at the copy-on-write split's worst case
    # of 3 transient node allocations, so the pool must leave at least 3 free
    # nodes for an insert to be attempted.
    my $t = Data::RadixTree::Shared->new(undef, 6, 65536);
    my @ok;
    my $croaked = 0;
    for my $c ('a' .. 'z') {
        if (eval { $t->insert($c, ord $c); 1 }) {
            push @ok, $c;
        } else {
            like $@, qr/exhausted/, 'node-pool exhaustion croak mentions exhausted';
            $croaked = 1;
            last;
        }
    }
    ok $croaked, 'inserting distinct keys eventually croaks on node-pool exhaustion';
    # the tree stays usable: every key inserted BEFORE the croak still resolves
    my $bad = 0;
    $bad++ for grep { $t->lookup($_) != ord($_) } @ok;
    is $bad, 0, 'all pre-exhaustion keys still look up correctly after the croak';
    is $t->count, scalar(@ok), 'count equals the number of successful inserts';
    ok $t->exists($ok[0]), 'first inserted key still exists after exhaustion croak';
}

# ---- capacity exhaustion: label arena ----
{
    # tiny arena: a handful of bytes. Distinct keys append their labels to the
    # arena, so enough distinct keys must exhaust the arena.
    my $t = Data::RadixTree::Shared->new(undef, 4096, 8);
    my @ok;
    my $croaked = 0;
    for my $i (0 .. 50) {
        my $key = "k$i";
        if (eval { $t->insert($key, $i); 1 }) {
            push @ok, $key;
        } else {
            like $@, qr/exhausted/, 'arena exhaustion croak mentions exhausted';
            $croaked = 1;
            last;
        }
    }
    ok $croaked, 'inserting distinct keys eventually croaks on arena exhaustion';
    my $bad = 0;
    for my $i (0 .. $#ok) {
        my $got = $t->lookup($ok[$i]);
        $bad++ unless defined($got) && $got == $i;
    }
    is $bad, 0, 'all pre-exhaustion keys still look up correctly after the arena croak';
    is $t->count, scalar(@ok), 'count equals the number of successful inserts';
}

# ---- reopen persists ----
my $path = "/tmp/rdx-basic-$$.bin";
unlink $path;
{
    my $w = Data::RadixTree::Shared->new($path, 4096, 65536);
    is $w->path, $path, 'file-backed path';
    $w->insert("10",       1);
    $w->insert("10.0",     2);
    $w->insert("10.0.0",   3);
    $w->insert("192.168",  9);
    is $w->count, 4, 'writer inserted 4 keys';
    $w->sync;
}
{
    my $r = Data::RadixTree::Shared->new($path, 4096, 65536);
    is $r->count, 4, 'reopen: count persisted';
    is $r->lookup("10.0.0"), 3, 'reopen: exact lookup persisted';
    is $r->longest_prefix("10.0.0.255"), 3, 'reopen: longest_prefix persisted';
    is $r->lookup("192.168"), 9, 'reopen: second branch persisted';
    ok !$r->exists("10.0.0.0"), 'reopen: a non-key is still absent';
}

# corrupt file rejected
{ open my $fh, '>', $path or die $!; print $fh "junk"; close $fh; }
ok !eval { Data::RadixTree::Shared->new($path, 4096, 65536); 1 }, 'too-small/corrupt file rejected';
unlink $path;

# ---- class-method unlink ----
my $cu = "/tmp/rdx-cu-$$.bin";
unlink $cu;
{ my $w = Data::RadixTree::Shared->new($cu, 16, 256); $w->sync; }
ok -e $cu, 'backing file exists';
Data::RadixTree::Shared->unlink($cu);
ok !-e $cu, 'class-method unlink removed the file';

# ---- instance-method unlink ----
my $iu = "/tmp/rdx-iu-$$.bin";
unlink $iu;
{
    my $w = Data::RadixTree::Shared->new($iu, 16, 256);
    ok -e $iu, 'instance backing file exists';
    $w->unlink;
    ok !-e $iu, 'instance-method unlink removed the file';
}

# ---- memfd round-trip shares the tree ----
{
    my $m  = Data::RadixTree::Shared->new_memfd('rdx', 4096, 65536);
    my $fd = $m->memfd;
    cmp_ok $fd, '>=', 0, 'memfd fd >= 0';
    my $m2 = Data::RadixTree::Shared->new_from_fd($fd);
    cmp_ok $m2->memfd, '>=', 0, 'new_from_fd exposes its (dup) backing fd';
    $m->insert("hello", 11);
    is $m2->lookup("hello"), 11, 'new_from_fd shares the tree';
    $m2->insert("world", 22);
    is $m->lookup("world"), 22, 'writes from the reopened handle are visible';
    ok !defined($m2->path), 'new_from_fd path is undef';
    my $mu = Data::RadixTree::Shared->new_memfd(undef, 16, 256);
    cmp_ok $mu->memfd, '>=', 0, 'new_memfd with undef name uses a default label';
}

# new_from_fd rejects a non-RDX file
{
    my $jp = "/tmp/rdx-junkfd-$$.bin";
    unlink $jp;
    open my $fh, '+>', $jp or die $!;
    print $fh "not a radix-tree table";
    $fh->flush if $fh->can('flush');
    ok !eval { Data::RadixTree::Shared->new_from_fd(fileno($fh)); 1 },
        'new_from_fd rejects a non-RDX file';
    like $@, qr/too small|invalid|radix/, 'new_from_fd junk-file croak message';
    close $fh;
    unlink $jp;
}

# ---- lock-leak regression ----
# A wide-char insert croaks BEFORE the write lock is taken (SvPVbyte croaks
# first). A follow-up lookup under a 5s alarm proves the lock was not leaked.
{
    my $t = Data::RadixTree::Shared->new(undef, 4096, 65536);
    $t->insert("ok", 1);
    ok !eval { $t->insert("bad-\x{2603}", 2); 1 }, 'wide-char insert croaks';
    my $survived = eval {
        local $SIG{ALRM} = sub { die "hung\n" };
        alarm 5;
        my $v = $t->lookup("ok");   # takes the read lock -- would hang if a write lock leaked
        alarm 0;
        $v;
    };
    is $survived, 1, 'lock not leaked: lookup works after the caught wide-char croak';
}

# also: a capacity-exhaustion croak releases the write lock before croaking.
# Fill a tiny node pool until insert croaks, swallowing the croak, then prove a
# follow-up read works under an alarm (the write lock must have been released).
{
    my $t = Data::RadixTree::Shared->new(undef, 4, 65536);
    for my $c ('a' .. 'z') { last unless eval { $t->insert($c, 1); 1 }; }
    my $survived = eval {
        local $SIG{ALRM} = sub { die "hung\n" };
        alarm 5;
        my $c = $t->count;          # takes the read lock -- would hang if the write lock leaked
        alarm 0;
        1;
    };
    ok $survived, 'lock not leaked after a capacity-exhaustion croak';
}

# ---- DESTROY nulls the handle ----
{
    my $i = Data::RadixTree::Shared->new(undef, 4096, 65536);
    $i->insert("k", 1);
    $i->DESTROY;
    eval { $i->lookup("k") };
    like $@, qr/destroyed/, 'use after DESTROY croaks (not a use-after-free)';
    eval { $i->DESTROY };
    pass 'double DESTROY did not crash';
}

done_testing;
