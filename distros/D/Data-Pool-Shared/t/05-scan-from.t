use strict;
use warnings;
use Test::More;
use Data::Pool::Shared;

# scan_from(0) -> deterministic, sequential (low-to-high) allocation, overriding
# the getpid()-derived spread start (which makes ids non-reproducible across runs).
{
    my $p = Data::Pool::Shared->new(undef, 4096, 1);
    $p->scan_from(0);
    is $p->alloc, 0, 'scan_from(0): first alloc is slot 0';
    is $p->alloc, 1, 'scan_from(0): second alloc is slot 1 (sequential)';
    is $p->alloc, 2, 'scan_from(0): third alloc is slot 2';
}

# an out-of-range slot wraps via % bitmap_words -- no OOB, alloc still works
{
    my $p = Data::Pool::Shared->new(undef, 256, 1);
    $p->scan_from(10_000_000);          # slot >> capacity
    my $i = $p->alloc;
    ok defined($i) && $i >= 0 && $i < 256, 'scan_from past capacity wraps safely, alloc ok';
}

# typed variants inherit scan_from from the base via @ISA
{
    my $p = Data::Pool::Shared::I64->new(undef, 1024);
    can_ok $p, 'scan_from';
    $p->scan_from(0);
    is $p->alloc, 0, 'I64 variant: scan_from(0) gives deterministic slot 0';
}

# fork: a child inheriting a scan_from(0) handle (COW) also allocates low
{
    my $p = Data::Pool::Shared->new(undef, 256, 8);
    $p->scan_from(0);
    my $pid = fork;
    if (!defined $pid) { ok 1, 'fork unavailable (skipped)'; }
    elsif ($pid == 0) { my $i = $p->alloc; exit(defined $i && $i == 0 ? 0 : 1); }
    else { waitpid $pid, 0; is $?, 0, 'fork: inherited scan_from(0) handle allocates slot 0'; }
}

done_testing;
