use strict;
use warnings;
use Test::More;
use Data::Fenwick2D::Shared;

# ----------------------------------------------------------------------------
# 2-D Fenwick tree (binary indexed tree): point update + rectangle sum query,
# cross-checked against a brute-force grid.
# ----------------------------------------------------------------------------

# construction + introspection
{
    my $f = Data::Fenwick2D::Shared->new(undef, 8, 5);
    isa_ok $f, 'Data::Fenwick2D::Shared';
    is $f->rows, 8, 'rows';
    is $f->cols, 5, 'cols';
    is $f->total, 0, 'fresh grid total 0';
    is $f->prefix(8, 5), 0, 'fresh prefix 0';
    is $f->point(4, 3), 0, 'fresh point 0';
    my $st = $f->stats;
    is $st->{rows}, 8, 'stats rows';
    is $st->{cols}, 5, 'stats cols';
    is $st->{total}, 0, 'stats total';
}

# bounds checks
{
    my $f = Data::Fenwick2D::Shared->new(undef, 4, 4);
    eval { $f->update(0, 1, 1) };  like $@, qr/out of range/, 'update row 0 croaks';
    eval { $f->update(5, 1, 1) };  like $@, qr/out of range/, 'update row 5 croaks';
    eval { $f->update(1, 5, 1) };  like $@, qr/out of range/, 'update col 5 croaks';
    eval { $f->point(0, 0) };      like $@, qr/out of range/, 'point (0,0) croaks';
    eval { $f->rect(2, 2, 1, 1) }; like $@, qr/bad rectangle/, 'rect x1>x2 croaks';
    eval { $f->rect(1, 1, 5, 1) }; like $@, qr/bad rectangle/, 'rect out of range croaks';
    is $f->prefix(0, 0), 0, 'prefix(0,0) is 0 (not an error)';
}

# ---- brute-force oracle: random updates, check every prefix + many rects ----
{
    my ($R, $C) = (7, 6);
    my $f = Data::Fenwick2D::Shared->new(undef, $R, $C);
    my @g = map { [ (0) x ($C + 1) ] } 0 .. $R;   # 1-based grid
    srand(31337);
    my $bad = 0;
    for my $step (1 .. 300) {
        my $x = 1 + int rand $R;
        my $y = 1 + int rand $C;
        my $d = int(rand 201) - 100;
        $f->update($x, $y, $d);
        $g[$x][$y] += $d;

        my $px = int rand($R + 1);   # 0..R
        my $py = int rand($C + 1);
        my $wp = 0;
        for my $i (1 .. $px) { for my $j (1 .. $py) { $wp += $g[$i][$j] } }
        $bad++ unless $f->prefix($px, $py) == $wp;

        my ($x1, $x2) = sort { $a <=> $b } (1 + int rand $R, 1 + int rand $R);
        my ($y1, $y2) = sort { $a <=> $b } (1 + int rand $C, 1 + int rand $C);
        my $wr = 0;
        for my $i ($x1 .. $x2) { for my $j ($y1 .. $y2) { $wr += $g[$i][$j] } }
        $bad++ unless $f->rect($x1, $y1, $x2, $y2) == $wr
                   && $f->point($x1, $y1) == $g[$x1][$y1];
    }
    is $bad, 0, '2-D oracle: 300 random updates match prefix/rect/point';
    my $wt = 0;
    for my $i (1 .. $R) { for my $j (1 .. $C) { $wt += $g[$i][$j] } }
    is $f->total, $wt, 'total matches brute-force grid sum';
}

# exhaustive: a single diagonal-cell update reaches exactly its covering prefixes
{
    my ($R, $C) = (5, 4);
    for my $u (1 .. 4) {
        my $f = Data::Fenwick2D::Shared->new(undef, $R, $C);
        $f->update($u, $u, 3);
        my $bad = 0;
        for my $x (0 .. $R) {
            for my $y (0 .. $C) {
                my $want = ($x >= $u && $y >= $u) ? 3 : 0;
                $bad++ unless $f->prefix($x, $y) == $want;
            }
        }
        is $bad, 0, "single update ($u,$u) reaches exactly the covering prefixes";
    }
}

# set() returns the old value and overwrites
{
    my $f = Data::Fenwick2D::Shared->new(undef, 4, 4);
    $f->update(2, 3, 10);
    is $f->set(2, 3, 42), 10, 'set returns the previous value';
    is $f->point(2, 3), 42, 'set overwrote the cell';
    is $f->set(1, 1, 7), 0, 'set on an empty cell returns 0';
}

# persistence via reopen
{
    my $path = "/tmp/fen2d-$$-" . int(rand 1e6) . ".shm";
    unlink $path;
    {
        my $w = Data::Fenwick2D::Shared->new($path, 10, 8);
        $w->update(5, 4, 100);
        $w->update(9, 7, 50);
        $w->sync;
    }
    {
        my $r = Data::Fenwick2D::Shared->new($path, 1, 1);   # dims ignored on reopen
        is $r->rows, 10, 'reopen: rows persisted';
        is $r->cols, 8, 'reopen: cols persisted';
        is $r->point(5, 4), 100, 'reopen: cell persisted';
        is $r->total, 150, 'reopen: total persisted';
    }
    unlink $path;
}

# memfd + cross-fd
{
    my $w = Data::Fenwick2D::Shared->new_memfd("f2d-demo", 6, 6);
    $w->update(3, 3, 9);
    my $fd = $w->memfd;
  SKIP: {
        skip "no memfd", 2 unless defined $fd && $fd >= 0;
        my $r2 = Data::Fenwick2D::Shared->new_from_fd($fd);
        is $r2->rows, 6, 'new_from_fd sees rows';
        is $r2->total, 9, 'shared grid visible via the other handle';
    }
}

# clear
{
    my $f = Data::Fenwick2D::Shared->new(undef, 5, 5);
    $f->update(3, 3, 20);
    $f->clear;
    is $f->total, 0, 'clear: total 0';
    is $f->point(3, 3), 0, 'clear: cell 0';
    $f->update(1, 1, 4);
    is $f->total, 4, 'usable after clear';
}

done_testing;
