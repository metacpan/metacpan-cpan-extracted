use strict;
use warnings;
use Test::More;
use Data::MinHash::Shared;

# de-duplicated union of two lists (avoids a List::Util version dependency)
sub union { my %u; $u{$_} = 1 for @{$_[0]}, @{$_[1]}; return keys %u }

# exact Jaccard for cross-checking the estimate
sub jaccard {
    my ($a, $b) = @_;
    my %ina = map { $_ => 1 } @$a;
    my $inter = grep { $ina{$_} } @$b;
    return $inter / scalar(union($a, $b));
}

# constructor + introspection
{
    my $mh = Data::MinHash::Shared->new(undef, 128);
    isa_ok $mh, 'Data::MinHash::Shared';
    is $mh->size, 128, 'size == k';
    is $mh->capacity, 128, 'capacity alias == k';
    is $mh->filled, 0, 'fresh sketch: 0 registers filled';
    my @r = $mh->registers;
    is scalar(@r), 128, 'registers() returns k values';
    is +(grep { $_ != 18446744073709551615 } @r), 0, 'all registers start at the empty sentinel (UINT64_MAX)';
}

# add semantics: first add fills every register, re-adding changes nothing
{
    my $mh = Data::MinHash::Shared->new(undef, 64);
    is $mh->add("hello"), 1, 'first add lowers at least one register';
    is $mh->filled, 64, 'after one add every register holds a value';
    is $mh->add("hello"), 0, 're-adding the same element changes nothing';
    # a fresh distinct element usually lowers some register (not guaranteed, but
    # over a handful of adds at least one must)
    my $any = 0;
    $any ||= $mh->add("w$_") for 1 .. 10;
    ok $any, 'adding new elements lowers some register';
}

# similarity: self == 1, disjoint ~ 0, known overlap within tolerance
{
    my $k = 512;
    my @a = (1 .. 1000);
    my @b = (500 .. 1500);       # |int|=501, |union|=1500 -> J ~ 0.334
    my @d = (10_001 .. 11_000);  # disjoint from @a

    my $A = Data::MinHash::Shared->new(undef, $k); $A->add($_) for @a;
    my $B = Data::MinHash::Shared->new(undef, $k); $B->add($_) for @b;
    my $D = Data::MinHash::Shared->new(undef, $k); $D->add($_) for @d;

    is $A->similarity($A), 1, 'similarity with self is exactly 1';
    my $sab = $A->similarity($B);
    my $tab = jaccard(\@a, \@b);
    cmp_ok abs($sab - $tab), '<', 0.06, "sim(A,B)=$sab within tolerance of true J=$tab";
    my $sad = $A->similarity($D);
    cmp_ok $sad, '<', 0.05, "disjoint sets estimate near 0 (got $sad)";

    # jaccard alias returns the same value
    is $A->jaccard($B), $sab, 'jaccard alias == similarity';

    # similarity is symmetric
    is $B->similarity($A), $sab, 'similarity is symmetric';
}

# two empty sketches are defined as similarity 1
{
    my $x = Data::MinHash::Shared->new(undef, 100);
    my $y = Data::MinHash::Shared->new(undef, 100);
    is $x->similarity($y), 1, 'two empty sketches: similarity 1';
}

# merge == sketch of the union
{
    my $k = 512;
    my @a = (1 .. 800);
    my @b = (600 .. 1400);
    my $A = Data::MinHash::Shared->new(undef, $k); $A->add($_) for @a;
    my $B = Data::MinHash::Shared->new(undef, $k); $B->add($_) for @b;

    # reference: one sketch built directly from the union
    my $U = Data::MinHash::Shared->new(undef, $k); $U->add($_) for union(\@a, \@b);

    $A->merge($B);
    is $A->similarity($U), 1, 'merged sketch is identical to the union sketch';
    is_deeply [$A->registers], [$U->registers], 'merged registers == union registers (element-wise min)';
}

# add_many
{
    my $mh = Data::MinHash::Shared->new(undef, 128);
    my $changed = $mh->add_many([ map { "m$_" } 1 .. 50 ]);
    cmp_ok $changed, '>', 0, 'add_many reports some registers lowered';
    is $mh->filled, 128, 'add_many filled the sketch';
    # same elements again -> nothing changes
    is $mh->add_many([ map { "m$_" } 1 .. 50 ]), 0, 're-add_many of the same set lowers nothing';
    # add_many matches a loop of add()
    my $loop = Data::MinHash::Shared->new(undef, 128);
    $loop->add($_) for map { "m$_" } 1 .. 50;
    is_deeply [$mh->registers], [$loop->registers], 'add_many == a loop of add()';
}

# clear
{
    my $mh = Data::MinHash::Shared->new(undef, 64);
    $mh->add("a"); $mh->add("b");
    is $mh->filled, 64, 'non-empty before clear';
    $mh->clear;
    is $mh->filled, 0, 'clear resets every register to empty';
    is +(grep { $_ != 18446744073709551615 } $mh->registers), 0, 'all registers back to the sentinel';
}

# stats
{
    my $mh = Data::MinHash::Shared->new(undef, 256);
    $mh->add("x$_") for 1 .. 20;
    my $st = $mh->stats;
    is ref($st), 'HASH', 'stats hashref';
    is $st->{size}, 256, 'stats size';
    is $st->{filled}, 256, 'stats filled';
    cmp_ok $st->{ops}, '>', 0, 'stats ops';
    ok exists $st->{mmap_size}, 'stats mmap_size';
}

# error paths
ok !eval { Data::MinHash::Shared->new(undef, 0); 1 }, 'k == 0 rejected';
like $@, qr/>= 1|must be/, 'k 0 croak';
{
    my $mh = Data::MinHash::Shared->new(undef, 64);
    ok !eval { $mh->add("snow-\x{2603}"); 1 }, 'add croaks on a wide-char element';
    like $@, qr/[Ww]ide/, 'wide-char croak';
    ok !eval { $mh->add_many("notaref"); 1 }, 'add_many non-arrayref croaks';
    # register-count mismatch
    my $other = Data::MinHash::Shared->new(undef, 32);
    ok !eval { $mh->similarity($other); 1 }, 'similarity croaks on k mismatch';
    like $@, qr/mismatch/, 'similarity mismatch croak';
    ok !eval { $mh->merge($other); 1 }, 'merge croaks on k mismatch';
    like $@, qr/mismatch/, 'merge mismatch croak';
    ok !eval { $mh->similarity("notanobject"); 1 }, 'similarity croaks on non-object';
}

# file-backed reopen: registers persist, stored k wins
my $path = "/tmp/mnh-basic-$$.bin";
unlink $path;
{
    my $w = Data::MinHash::Shared->new($path, 128);
    is $w->path, $path, 'file-backed path';
    $w->add("p$_") for 1 .. 100;
    $w->sync;
    my @regs = $w->registers;
    # reopen with different caller args -> stored k wins, registers intact
    my $r = Data::MinHash::Shared->new($path, 999);
    is $r->size, 128, 'reopen: stored k wins';
    is_deeply [$r->registers], \@regs, 'reopen: registers persisted';
    is $r->similarity($w), 1, 'reopened sketch identical to the writer';
}
{ open my $fh, '>', $path or die $!; print $fh "junk"; close $fh; }
ok !eval { Data::MinHash::Shared->new($path, 128); 1 }, 'corrupt file rejected';
unlink $path;

# memfd round-trip shares the sketch
{
    my $m  = Data::MinHash::Shared->new_memfd('mnh', 128);
    my $fd = $m->memfd;
    cmp_ok $fd, '>=', 0, 'memfd fd >= 0';
    my $m2 = Data::MinHash::Shared->new_from_fd($fd);
    is $m2->size, 128, 'reopened memfd size';
    $m->add("shared");
    is $m2->filled, 128, 'new_from_fd shares the registers';
    is $m2->similarity($m), 1, 'both handles see one sketch';
}

# class-method unlink
my $cu = "/tmp/mnh-cu-$$.bin";
unlink $cu;
{ my $w = Data::MinHash::Shared->new($cu, 64); $w->sync; }
ok -e $cu, 'backing file exists';
Data::MinHash::Shared->unlink($cu);
ok !-e $cu, 'class-method unlink removed the file';

# DESTROY
{
    my $i = Data::MinHash::Shared->new(undef, 64);
    $i->add("x");
    $i->DESTROY;
    eval { $i->filled };
    like $@, qr/destroyed/, 'use after DESTROY croaks';
    eval { $i->DESTROY };
    pass 'double DESTROY did not crash';
}

done_testing;
