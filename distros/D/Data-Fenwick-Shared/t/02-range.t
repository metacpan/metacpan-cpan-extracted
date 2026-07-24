use strict;
use warnings;
use Test::More;
use Data::Fenwick::Shared;

# ----------------------------------------------------------------------------
# Range-mode (two-BIT) Fenwick: range_add + range query, vs a brute-force array.
# ----------------------------------------------------------------------------

# introspection + point/range coexistence
{
    my $f = Data::Fenwick::Shared->new_range(undef, 8);
    isa_ok $f, 'Data::Fenwick::Shared';
    ok $f->is_range, 'is_range true for a range-mode tree';
    is $f->stats->{range}, 1, 'stats reports range mode';

    my $p = Data::Fenwick::Shared->new(undef, 8);
    ok !$p->is_range, 'is_range false for a point-mode tree';
    is $p->stats->{range}, 0, 'stats reports point mode';
}

# range-mode-only / point-mode-only method gating
{
    my $p = Data::Fenwick::Shared->new(undef, 8);
    eval { $p->range_add(1, 4, 3) };
    like $@, qr/requires a range-mode tree/, 'range_add croaks on a point tree';

    my $r = Data::Fenwick::Shared->new_range(undef, 8);
    eval { $r->find(1) };  like $@, qr/not supported on a range-mode/, 'find croaks on a range tree';
    my $r2 = Data::Fenwick::Shared->new_range(undef, 8);
    eval { $r->merge($r2) }; like $@, qr/not supported for range-mode/, 'merge croaks on range trees';
}

# ---- brute-force oracle: random range_add / update / set, check prefix/range ----
{
    my $N = 50;
    my $f = Data::Fenwick::Shared->new_range(undef, $N);
    my @a = (0) x ($N + 1);          # 1-based reference array
    srand(4242);
    my $bad = 0;
    for my $step (1 .. 500) {
        my ($l, $r) = sort { $a <=> $b } (1 + int(rand $N), 1 + int(rand $N));
        my $k = int rand 3;
        if ($k == 0) {               # range_add
            my $d = int(rand 2001) - 1000;
            $f->range_add($l, $r, $d);
            $a[$_] += $d for $l .. $r;
        } elsif ($k == 1) {          # point add via update()
            my $i = 1 + int(rand $N);
            my $d = int(rand 2001) - 1000;
            $f->update($i, $d);
            $a[$i] += $d;
        } else {                     # absolute set
            my $i = 1 + int(rand $N);
            my $v = int(rand 2001) - 1000;
            $f->set($i, $v);
            $a[$i] = $v;
        }
        # check a random prefix and a random range against brute force
        my $pi = int rand($N + 1);   # 0..N
        my $want_pref = 0; $want_pref += $a[$_] for 1 .. $pi;
        $bad++ unless $f->prefix($pi) == $want_pref;

        my ($ql, $qr) = sort { $a <=> $b } (1 + int(rand $N), 1 + int(rand $N));
        my $want_rng = 0; $want_rng += $a[$_] for $ql .. $qr;
        $bad++ unless $f->range($ql, $qr) == $want_rng
                   && $f->point($ql) == $a[$ql];
    }
    is $bad, 0, 'range-mode oracle: 500 random range_add/update/set match prefix/range/point';
    my $want_total = 0; $want_total += $a[$_] for 1 .. $N;
    is $f->total, $want_total, 'total matches the brute-force sum';
}

# ---- persistence: a range-mode tree reopened from its file stays range mode ----
{
    my $path = "/tmp/fen-range-$$-" . int(rand 1e6) . ".shm";
    unlink $path;
    {
        my $w = Data::Fenwick::Shared->new_range($path, 20);
        $w->range_add(5, 15, 7);
        $w->sync;
    }
    {
        my $r = Data::Fenwick::Shared->new_range($path, 1);   # geometry ignored on reopen
        ok $r->is_range, 'reopened tree is still range mode';
        is $r->size, 20, 'reopen: stored n wins';
        is $r->range(5, 15), 7 * 11, 'reopen: range values persisted';
        is $r->point(10), 7, 'reopen: point value persisted';
        is $r->point(4), 0, 'reopen: outside the added range is 0';
    }
    unlink $path;
}

# ---- memfd + cross-fd carry the range mode via the header ----
{
    my $w = Data::Fenwick::Shared->new_range_memfd("fen-range-demo", 10);
    ok $w->is_range, 'new_range_memfd is range mode';
    $w->range_add(1, 10, 3);
    my $fd = $w->memfd;
  SKIP: {
        skip "no memfd", 2 unless defined $fd && $fd >= 0;
        my $r2 = Data::Fenwick::Shared->new_from_fd($fd);
        ok $r2->is_range, 'new_from_fd sees the range mode';
        is $r2->total, 30, 'shared range data visible via the other handle';
    }
}

# ---- clear resets both BITs ----
{
    my $f = Data::Fenwick::Shared->new_range(undef, 16);
    $f->range_add(1, 16, 9);
    $f->clear;
    is $f->total, 0, 'clear: total 0';
    is $f->range(1, 16), 0, 'clear: range 0';
    $f->range_add(2, 4, 1);
    is $f->total, 3, 'usable after clear';
}

done_testing;
