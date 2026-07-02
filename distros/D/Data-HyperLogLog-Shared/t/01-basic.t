use strict;
use warnings;
use Test::More;
use Data::HyperLogLog::Shared;

# anonymous, default precision
my $hll = Data::HyperLogLog::Shared->new;
isa_ok $hll, 'Data::HyperLogLog::Shared';
is $hll->precision, 14, 'default precision is 14';
is $hll->registers, 1 << 14, 'registers == 2**precision';
is $hll->count, 0, 'fresh count == 0';
ok !defined($hll->path), 'anonymous path is undef';

# explicit precision
my $h12 = Data::HyperLogLog::Shared->new(undef, 12);
is $h12->precision, 12, 'explicit precision honored';
is $h12->registers, 1 << 12, 'registers for precision 12';

# add returns 1 the first time a register moves, 0 on a repeat of the same item
my $first = $hll->add("hot-register-item");
is $first, 1, 'first add of a fresh item bumps a register';
my $again = $hll->add("hot-register-item");
is $again, 0, 'repeat add of the same item does not bump (already maxed)';

# count grows as distinct items are added
my $before = $hll->count;
$hll->add("a-$_") for 1 .. 500;
my $after = $hll->count;
cmp_ok $after, '>', $before, 'count grows with distinct additions';

# add_many returns number of items that moved a register
my $fresh = Data::HyperLogLog::Shared->new;
my $added = $fresh->add_many([ map { "item-$_" } 1 .. 1000 ]);
cmp_ok $added, '>', 0, 'add_many reports items added';
cmp_ok $added, '<=', 1000, 'add_many added at most the batch size';

# stats keys
my $st = $fresh->stats;
is ref($st), 'HASH', 'stats returns a hashref';
ok exists $st->{$_}, "stats has $_"
    for qw(precision registers count ops mmap_size);
is $st->{precision}, 14, 'stats precision';
is $st->{registers}, 1 << 14, 'stats registers';
cmp_ok $st->{ops}, '>', 0, 'stats ops counted the add_many write';
{
    my $b4 = $fresh->stats->{ops};
    is $fresh->add_many([]), 0, 'empty add_many adds nothing';
    is $fresh->stats->{ops}, $b4 + 1, 'an empty add_many still counts as one write op';
}

# clear resets to empty
$fresh->clear;
is $fresh->count, 0, 'clear -> count 0';

# error paths: precision out of range
ok !eval { Data::HyperLogLog::Shared->new(undef, 3); 1 }, 'precision 3 rejected';
like $@, qr/precision/, 'precision 3 croak mentions precision';
ok !eval { Data::HyperLogLog::Shared->new(undef, 19); 1 }, 'precision 19 rejected';
like $@, qr/precision/, 'precision 19 croak mentions precision';

# error paths: new_memfd precision out of range
ok !eval { Data::HyperLogLog::Shared->new_memfd('x', 3); 1 }, 'new_memfd precision 3 rejected';
like $@, qr/precision/, 'new_memfd precision 3 croak mentions precision';
ok !eval { Data::HyperLogLog::Shared->new_memfd('x', 19); 1 }, 'new_memfd precision 19 rejected';
like $@, qr/precision/, 'new_memfd precision 19 croak mentions precision';

# regression: a wide-char element makes add_many croak but must NOT leak the write lock
{
    my $h = Data::HyperLogLog::Shared->new(undef, 12);
    $h->add("ascii-seed");
    # codepoint > 255 (snowman) so SvPVbyte raises "Wide character"
    ok !eval { $h->add_many(["ok", "snow-\x{2603}"]); 1 }, 'add_many croaks on a wide-char element';
    my $survived = eval { local $SIG{ALRM} = sub { die "hung\n" }; alarm 5; my $c = $h->count; alarm 0; 1 };
    ok $survived, 'write lock not leaked: count works after the caught add_many croak';
}

# error path: merge of mismatched precision croaks
{
    my $a = Data::HyperLogLog::Shared->new(undef, 14);
    my $b = Data::HyperLogLog::Shared->new(undef, 12);
    ok !eval { $a->merge($b); 1 }, 'merge of mismatched precision croaks';
    like $@, qr/precision mismatch/, 'merge mismatch croak message';
}

# merge of equal precision works
{
    my $a = Data::HyperLogLog::Shared->new(undef, 14);
    my $b = Data::HyperLogLog::Shared->new(undef, 14);
    $a->add_many([ map { "x-$_" } 1 .. 1000 ]);
    $b->add_many([ map { "y-$_" } 1 .. 1000 ]);
    my $ca = $a->count;
    $a->merge($b);
    cmp_ok $a->count, '>', $ca, 'merge increases the union estimate';
}

# memfd round-trip
my $m  = Data::HyperLogLog::Shared->new_memfd('hll', 14);
my $fd = $m->memfd;
cmp_ok $fd, '>=', 0, 'memfd fd >= 0';
my $mu = Data::HyperLogLog::Shared->new_memfd(undef, 10);
cmp_ok $mu->memfd, '>=', 0, 'new_memfd with undef name uses a default label';
my $m2 = Data::HyperLogLog::Shared->new_from_fd($fd);
cmp_ok $m2->memfd, '>=', 0, 'new_from_fd handle exposes its (dup) backing fd';
is $m2->precision, 14, 'reopened memfd precision';
$m->add("shared-x");
is $m2->count, $m->count, 'new_from_fd shares the register mapping';
ok !defined($m2->path), 'new_from_fd path is undef';

# file-backed reopen: stored precision wins, registers persist
my $path = "/tmp/hll-basic-$$.bin";
unlink $path;
{
    my $w = Data::HyperLogLog::Shared->new($path, 14);
    is $w->path, $path, 'file-backed path';
    $w->add_many([ map { "p-$_" } 1 .. 5000 ]);
    $w->sync;
}
{
    my $r = Data::HyperLogLog::Shared->new($path, 8);   # caller precision ignored on reopen
    is $r->precision, 14, 'reopen: stored precision wins';
    cmp_ok $r->count, '>', 4000, 'reopen: registers persisted (count survives)';
    cmp_ok $r->count, '<', 6000, 'reopen: persisted count is in range';
}

# corrupt file rejected
{ open my $fh, '>', $path or die $!; print $fh "junk"; close $fh; }
ok !eval { Data::HyperLogLog::Shared->new($path, 14); 1 }, 'too-small/corrupt file rejected';
unlink $path;

# class-method unlink
my $cu = "/tmp/hll-cu-$$.bin";
unlink $cu;
{ my $w = Data::HyperLogLog::Shared->new($cu, 10); $w->sync; }
ok -e $cu, 'backing file exists';
Data::HyperLogLog::Shared->unlink($cu);
ok !-e $cu, 'class-method unlink removed the file';

# instance-method unlink
my $iu = "/tmp/hll-iu-$$.bin";
unlink $iu;
{
    my $w = Data::HyperLogLog::Shared->new($iu, 10);
    ok -e $iu, 'instance backing file exists';
    $w->unlink;
    ok !-e $iu, 'instance-method unlink removed the file';
}

# DESTROY nulls the handle: use-after-destroy croaks cleanly, double DESTROY is a no-op
{
    my $i = Data::HyperLogLog::Shared->new;
    $i->add("x");
    $i->DESTROY;
    eval { $i->count };
    like $@, qr/destroyed/, 'use after DESTROY croaks (not a use-after-free)';
}
pass 'double DESTROY did not crash';

done_testing;
