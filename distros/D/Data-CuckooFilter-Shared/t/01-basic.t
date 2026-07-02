use strict;
use warnings;
use Test::More;
use Data::CuckooFilter::Shared;

# constructor: capacity, anonymous mapping
my $cf = Data::CuckooFilter::Shared->new(undef, 1000);
isa_ok $cf, 'Data::CuckooFilter::Shared';
is $cf->capacity, 1000, 'capacity stored';
ok !defined($cf->path), 'anonymous path is undef';

# geometry sanity: buckets a power of two, slots == 4 * buckets
my $buckets = $cf->buckets;
ok $buckets >= 2, 'buckets >= 2';
is $buckets & ($buckets - 1), 0, 'buckets is a power of two';
is $cf->slots, $buckets * 4, 'slots == 4 * buckets';

# add returns 1; contains added (1), never-added (0)
is $cf->add("hello"), 1, 'add of a fresh item returns 1';
ok $cf->contains("hello"), 'contains true for an added item';
ok !$cf->contains("never-added-xyz"), 'contains false for a never-added item';

# remove returns 1, then contains is 0; remove of an absent item returns 0
is $cf->remove("hello"), 1, 'remove of a present item returns 1';
ok !$cf->contains("hello"), 'contains false after remove';
is $cf->remove("hello"), 0, 'remove of an already-absent item returns 0';
is $cf->remove("never-added-zzz"), 0, 'remove of a never-added item returns 0';

# no false negatives: add 1000, assert all contained
{
    my $h = Data::CuckooFilter::Shared->new(undef, 1000);
    my $store_miss = 0; $h->add("k-$_") == 1 or $store_miss++ for 0 .. 999;
    is $store_miss, 0, 'all 1000 distinct adds stored (returned 1)';
    my $miss = 0;
    $h->contains("k-$_") or $miss++ for 0 .. 999;
    is $miss, 0, 'no false negatives: all 1000 added items are contained';
    is $h->count, 1000, 'count == 1000 live fingerprints after 1000 adds';
}

# count tracks adds and removes (count == live items after a churn)
{
    my $h = Data::CuckooFilter::Shared->new(undef, 2000);
    $h->add("churn-$_") for 0 .. 999;
    is $h->count, 1000, 'count is 1000 after 1000 adds';
    $h->remove("churn-$_") for 0 .. 499;     # remove half
    is $h->count, 500, 'count drops to 500 after removing 500';
    $h->add("more-$_") for 0 .. 299;         # add 300 more
    is $h->count, 800, 'count is 800 after adding 300 more';
    # the survivors must all still be present (no false negatives)
    my $miss = 0;
    $h->contains("churn-$_") or $miss++ for 500 .. 999;
    $h->contains("more-$_")  or $miss++ for 0 .. 299;
    is $miss, 0, 'all live items still contained after churn';
}

# add_many returns the count stored; re-add stores duplicates (no dedup)
{
    my $h = Data::CuckooFilter::Shared->new(undef, 4000);
    my $added = $h->add_many([ map { "m-$_" } 1 .. 1000 ]);
    is $added, 1000, 'add_many stored all 1000 items';
    is $h->count, 1000, 'count == 1000 after add_many';
    my $again = $h->add_many([ map { "m-$_" } 1 .. 1000 ]);
    is $again, 1000, 'add_many again stores 1000 more (cuckoo filter does not dedup)';
    is $h->count, 2000, 'count == 2000 after a second identical add_many (duplicates stored)';
}

# self-op edge: add the same item twice stores a duplicate; both removable
{
    my $h = Data::CuckooFilter::Shared->new(undef, 1000);
    is $h->add("dup"), 1, 'first add of dup';
    is $h->add("dup"), 1, 'second add of dup also stored';
    is $h->count, 2, 'count is 2 after adding the same item twice';
    ok $h->contains("dup"), 'dup is contained';
    is $h->remove("dup"), 1, 'first remove of dup';
    ok $h->contains("dup"), 'dup still contained after one remove (a duplicate remains)';
    is $h->remove("dup"), 1, 'second remove of dup';
    ok !$h->contains("dup"), 'dup gone after both removes';
    is $h->count, 0, 'count back to 0';
}

# stats keys + fill_ratio in [0,1]
{
    my $h = Data::CuckooFilter::Shared->new(undef, 1000);
    $h->add_many([ map { "s-$_" } 1 .. 500 ]);
    my $st = $h->stats;
    is ref($st), 'HASH', 'stats returns a hashref';
    ok exists $st->{$_}, "stats has $_"
        for qw(capacity buckets slots count fill_ratio ops mmap_size);
    is $st->{capacity}, 1000, 'stats capacity';
    is $st->{buckets}, $h->buckets, 'stats buckets matches accessor';
    is $st->{slots}, $h->slots, 'stats slots matches accessor';
    is $st->{count}, 500, 'stats count matches 500 adds';
    cmp_ok $st->{fill_ratio}, '>=', 0, 'fill_ratio >= 0';
    cmp_ok $st->{fill_ratio}, '<=', 1, 'fill_ratio <= 1';
    cmp_ok $st->{ops}, '>', 0, 'stats ops counted the add_many write';
    {
        my $b4 = $h->stats->{ops};
        is $h->add_many([]), 0, 'empty add_many adds nothing';
        is $h->stats->{ops}, $b4 + 1, 'an empty add_many still counts as one write op';
    }
}

# add atomicity (sanity, not a forced fill): a normal add+contains roundtrip
# and exact count after a churn of adds and removes.
{
    my $h = Data::CuckooFilter::Shared->new(undef, 5000);
    is $h->add("atomic-seed"), 1, 'atomic: add stored';
    ok $h->contains("atomic-seed"), 'atomic: roundtrip contains';
    my $live = 0;
    for my $i (0 .. 1999) { $h->add("a-$i"); $live++ }
    for my $i (0 .. 999)  { $h->remove("a-$i"); $live-- }   # remove the first 1000
    for my $i (2000 .. 2499) { $h->add("a-$i"); $live++ }
    is $h->count, $live + 1, 'count exact after a churn of adds and removes';
}

# clear -> count 0, contains false
{
    my $h = Data::CuckooFilter::Shared->new(undef, 1000);
    $h->add("gone");
    ok $h->contains("gone"), 'present before clear';
    $h->clear;
    is $h->count, 0, 'clear -> count 0';
    ok !$h->contains("gone"), 'clear -> contains false';
}

# error paths: bad capacity
ok !eval { Data::CuckooFilter::Shared->new(undef, 0); 1 }, 'capacity 0 rejected';
like $@, qr/capacity/, 'capacity 0 croak mentions capacity';
ok !eval { Data::CuckooFilter::Shared->new_memfd('x', 0); 1 }, 'new_memfd capacity 0 rejected';
like $@, qr/capacity/, 'new_memfd capacity 0 croak mentions capacity';
# a capacity so large it would exceed the 2^38 bucket cap must croak, not
# silently cap to an undersized filter that overflows at the requested load
ok !eval { Data::CuckooFilter::Shared->new(undef, 10**13); 1 }, 'over-cap capacity rejected';
like $@, qr/too large/, 'over-cap capacity croak mentions too large';

# error path: add_many requires an array reference
{
    my $h = Data::CuckooFilter::Shared->new(undef, 1000);
    ok !eval { $h->add_many("notaref"); 1 }, 'add_many croaks on a non-arrayref scalar';
    like $@, qr/array reference/, 'add_many non-arrayref croak mentions array reference';
    ok !eval { $h->add_many({}); 1 }, 'add_many croaks on a hashref';
    like $@, qr/array reference/, 'add_many hashref croak mentions array reference';

    # single add/contains/remove of a wide-char item croaks (codepoint > 255)
    ok !eval { $h->add("snow-\x{2603}"); 1 }, 'add croaks on a wide-char item';
    like $@, qr/[Ww]ide/, 'add wide-char croak mentions Wide character';
    ok !eval { $h->contains("snow-\x{2603}"); 1 }, 'contains croaks on a wide-char item';
    ok !eval { $h->remove("snow-\x{2603}"); 1 }, 'remove croaks on a wide-char item';
}

# file-backed reopen: add, sync, reopen, still contains
my $path = "/tmp/cuckoo-basic-$$.bin";
unlink $path;
{
    my $w = Data::CuckooFilter::Shared->new($path, 5000);
    is $w->path, $path, 'file-backed path';
    $w->add_many([ map { "p-$_" } 1 .. 3000 ]);
    $w->sync;
}
{
    my $r = Data::CuckooFilter::Shared->new($path, 1);   # caller args ignored on reopen
    is $r->capacity, 5000, 'reopen: stored capacity wins';
    ok $r->contains("p-1500"), 'reopen: membership persisted';
    my $miss = 0;
    $r->contains("p-$_") or $miss++ for 1 .. 3000;
    is $miss, 0, 'reopen: no false negatives after persistence';
}

# corrupt file rejected
{ open my $fh, '>', $path or die $!; print $fh "junk"; close $fh; }
ok !eval { Data::CuckooFilter::Shared->new($path, 1000); 1 }, 'too-small/corrupt file rejected';
unlink $path;

# new_from_fd error path: a valid fd over a non-Cuckoo file is rejected
{
    my $jp = "/tmp/cuckoo-junkfd-$$.bin";
    unlink $jp;
    open my $fh, '+>', $jp or die $!;   # real filehandle -> fileno is valid
    print $fh "not a cuckoo table";
    $fh->flush if $fh->can('flush');
    ok !eval { Data::CuckooFilter::Shared->new_from_fd(fileno($fh)); 1 },
        'new_from_fd rejects a non-Cuckoo file';
    like $@, qr/too small|invalid|Cuckoo/, 'new_from_fd junk-file croak message';
    close $fh;
    unlink $jp;
}

# memfd round-trip shares the table
{
    my $m  = Data::CuckooFilter::Shared->new_memfd('cuckoo', 1000);
    my $fd = $m->memfd;
    cmp_ok $fd, '>=', 0, 'memfd fd >= 0';
    my $m2 = Data::CuckooFilter::Shared->new_from_fd($fd);
    cmp_ok $m2->memfd, '>=', 0, 'new_from_fd exposes its (dup) backing fd';
    is $m2->capacity, 1000, 'reopened memfd capacity';
    $m->add("shared-x");
    ok $m2->contains("shared-x"), 'new_from_fd shares the table';
    ok !defined($m2->path), 'new_from_fd path is undef';
    my $mu = Data::CuckooFilter::Shared->new_memfd(undef, 100);
    cmp_ok $mu->memfd, '>=', 0, 'new_memfd with undef name uses a default label';
}

# class-method unlink
my $cu = "/tmp/cuckoo-cu-$$.bin";
unlink $cu;
{ my $w = Data::CuckooFilter::Shared->new($cu, 100); $w->sync; }
ok -e $cu, 'backing file exists';
Data::CuckooFilter::Shared->unlink($cu);
ok !-e $cu, 'class-method unlink removed the file';

# instance-method unlink
my $iu = "/tmp/cuckoo-iu-$$.bin";
unlink $iu;
{
    my $w = Data::CuckooFilter::Shared->new($iu, 100);
    ok -e $iu, 'instance backing file exists';
    $w->unlink;
    ok !-e $iu, 'instance-method unlink removed the file';
}

# lock-leak regression: a wide-char element makes add_many croak, and a
# follow-up contains() under an alarm proves the write lock was not leaked.
{
    my $h = Data::CuckooFilter::Shared->new(undef, 1000);
    $h->add("ascii-seed");
    # codepoint > 255 (snowman) so SvPVbyte raises "Wide character"
    ok !eval { $h->add_many(["ok", "snow-\x{2603}"]); 1 }, 'add_many croaks on a wide-char element';
    my $survived = eval {
        local $SIG{ALRM} = sub { die "hung\n" };
        alarm 5;
        my $c = $h->contains("ascii-seed");
        alarm 0;
        1;
    };
    ok $survived, 'write lock not leaked: contains works after the caught add_many croak';
}

# DESTROY nulls the handle: use-after-destroy croaks, double DESTROY is a no-op
{
    my $i = Data::CuckooFilter::Shared->new(undef, 100);
    $i->add("x");
    $i->DESTROY;
    eval { $i->contains("x") };
    like $@, qr/destroyed/, 'use after DESTROY croaks (not a use-after-free)';
    eval { $i->DESTROY };
    pass 'double DESTROY did not crash';
}

done_testing;
