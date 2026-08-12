use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Heap::Shared;

# A creator killed between ftruncate() and header init leaves a full-size,
# all-zero (magic==0) file.  new() must recover it instead of bricking the path,
# but must never clobber a valid or foreign file.

my $dir = tempdir(CLEANUP => 1);
my $p   = "$dir/recover.heap";

# Learn the on-disk size for this geometry.
{ my $b = Data::Heap::Shared->new($p, 10); }
my $total = -s $p;
unlink $p;

# 1. Recovery: an abandoned all-zero file of exactly $total bytes is re-initialized.
{
    open my $f, '>', $p or die $!; truncate $f, $total or die $!; close $f;
    is(-s $p, $total, "abandoned file is $total bytes (a killed creator's ftruncate)");
    my $b = eval { Data::Heap::Shared->new($p, 10) };
    ok($b, "new() recovers an abandoned mid-init file instead of bricking") or diag $@;
  SKIP: {
        skip "no handle", 4 unless $b;
        is($b->size, 0, "recovered heap starts empty (size 0)");
        my @r = $b->peek;
        is(scalar @r, 0, "recovered heap peek returns () when empty");
        ok($b->push(5, 500), "push onto recovered heap");
        ok($b->push(1, 100), "push onto recovered heap");
        $b->push(3, 300);
        my ($pri, $val) = $b->peek;
        is($pri, 1, "recovered heap orders correctly (peek min)");
        is($val, 100);
        ($pri, $val) = $b->pop;
        is($pri, 1, "recovered heap pop returns min first");
        is($val, 100);
        is($b->size, 2, "size updated after pop");
    }
    undef $b; unlink $p;
}

# 2. No clobber: a file with nonzero (foreign) magic still errors.
{
    open my $f, '>', $p or die $!; print $f "XXXX"; truncate $f, $total or die $!; close $f;
    my $b = eval { Data::Heap::Shared->new($p, 10) };
    ok(!$b, "new() refuses a foreign nonzero-magic file (no clobber)");
    like($@, qr/invalid/i, "  ... reporting an invalid file");
    undef $b; unlink $p;
}

# 3. No recovery for the wrong size: magic==0 but size != total still errors.
{
    open my $f, '>', $p or die $!; truncate $f, $total + 8 or die $!; close $f;
    my $b = eval { Data::Heap::Shared->new($p, 10) };
    ok(!$b, "new() refuses an uninitialized file of the wrong size");
    undef $b; unlink $p;
}

# 4. A valid file is attached, never re-initialized (its data survives).
{
    my $a = Data::Heap::Shared->new($p, 10); $a->push(9, 900); undef $a;
    my $r = Data::Heap::Shared->new($p, 10);
    is($r->size, 1, "reopening a valid file preserves its size");
    my ($pri, $val) = $r->peek;
    is($pri, 9, "reopening a valid file preserves its data (priority)");
    is($val, 900, "  ... (value)");
    undef $r; unlink $p;
}

# 5. A magic==0 file of the right size but with NON-zero data (not a fresh
#    ftruncate) is NOT recovered -- recovery only re-inits a provably-empty file.
{
    open my $f, '>', $p or die $!; truncate $f, $total or die $!; close $f;
    open $f, '+<', $p or die $!; seek $f, $total - 1, 0; print $f "\x01"; close $f;
    my $b = eval { Data::Heap::Shared->new($p, 10) };
    ok(!$b, "new() refuses a magic==0 file that is not all-zero (no clobber of real data)");
    undef $b; unlink $p;
}

done_testing;
