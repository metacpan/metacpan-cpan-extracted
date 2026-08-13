use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::SegmentTree::Shared;

# A creator killed between ftruncate() and header init leaves a full-size,
# all-zero (magic==0) file.  new() must recover it instead of bricking the path,
# but must never clobber a valid or foreign file.

my $dir = tempdir(CLEANUP => 1);
my $p   = "$dir/recover.st";
my $n   = 200;

# Learn the on-disk size for this geometry.
{ my $st = Data::SegmentTree::Shared->new($p, $n); }
my $total = -s $p;
unlink $p;

# 1. Recovery: an abandoned all-zero file of exactly $total bytes is re-initialized.
{
    open my $f, '>', $p or die $!; truncate $f, $total or die $!; close $f;
    is(-s $p, $total, "abandoned file is $total bytes (a killed creator's ftruncate)");
    my $st = eval { Data::SegmentTree::Shared->new($p, $n) };
    ok($st, "new() recovers an abandoned mid-init file instead of bricking") or diag $@;
  SKIP: {
        skip "no handle", 4 unless $st;
        is($st->get(0), 0, "recovered tree reads identity/0 first (get)");
        is($st->sum(0, $n - 1), 0, "recovered tree reads identity/0 first (range sum)");
        $st->set(10, 42);
        is($st->get(10), 42, "recovered tree works (update then point readback)");
        is($st->sum(0, $n - 1), 42, "recovered tree works (update then range readback)");
    }
    undef $st; unlink $p;
}

# 2. No clobber: a file with nonzero (foreign) magic still errors.
{
    open my $f, '>', $p or die $!; print $f "XXXX"; truncate $f, $total or die $!; close $f;
    my $st = eval { Data::SegmentTree::Shared->new($p, $n) };
    ok(!$st, "new() refuses a foreign nonzero-magic file (no clobber)");
    like($@, qr/invalid/i, "  ... reporting an invalid file");
    undef $st; unlink $p;
}

# 3. No recovery for the wrong size: magic==0 but size != total still errors.
{
    open my $f, '>', $p or die $!; truncate $f, $total + 8 or die $!; close $f;
    my $st = eval { Data::SegmentTree::Shared->new($p, $n) };
    ok(!$st, "new() refuses an uninitialized file of the wrong size");
    undef $st; unlink $p;
}

# 4. A valid file is attached, never re-initialized (its data survives).
{
    my $a = Data::SegmentTree::Shared->new($p, $n); $a->set(10, 42); undef $a;
    my $r = Data::SegmentTree::Shared->new($p, $n);
    is($r->get(10), 42, "reopening a valid file preserves its data");
    undef $r; unlink $p;
}
# 5. A magic==0 file of the right size but with NON-zero data (not a fresh
#    ftruncate) is NOT recovered -- recovery only re-inits a provably-empty file.
{
    open my $zfh, '>', $p or die $!; truncate $zfh, $total or die $!; close $zfh;
    open $zfh, '+<', $p or die $!; seek $zfh, $total - 1, 0; print $zfh "\x01"; close $zfh;
    my $st = eval { Data::SegmentTree::Shared->new($p, $n) };
    ok(!$st, "new() refuses a magic==0 file that is not all-zero (no clobber of real data)");
    undef $st; unlink $p;
}

done_testing;
