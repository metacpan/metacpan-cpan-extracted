use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::CountingBloomFilter::Shared;

# A creator killed between ftruncate() and header init leaves a full-size,
# all-zero (magic==0) file.  new() must recover it instead of bricking the path,
# but must never clobber a valid or foreign file.

my $dir = tempdir(CLEANUP => 1);
my $p   = "$dir/recover.cbf";

# Learn the on-disk size for this geometry.
{ my $b = Data::CountingBloomFilter::Shared->new($p, 1000, 0.01); }
my $total = -s $p;
unlink $p;

# 1. Recovery: an abandoned all-zero file of exactly $total bytes is re-initialized.
{
    open my $f, '>', $p or die $!; truncate $f, $total or die $!; close $f;
    is(-s $p, $total, "abandoned file is $total bytes (a killed creator's ftruncate)");
    my $b = eval { Data::CountingBloomFilter::Shared->new($p, 1000, 0.01) };
    ok($b, "new() recovers an abandoned mid-init file instead of bricking") or diag $@;
  SKIP: {
        skip "no handle", 2 unless $b;
        $b->add("x");
        ok($b->contains("x"),  "recovered filter works (add/contains)");
        ok(!$b->contains("y"), "recovered filter starts empty (no stale membership)");
    }
    undef $b; unlink $p;
}

# 2. No clobber: a file with nonzero (foreign) magic still errors.
{
    open my $f, '>', $p or die $!; print $f "XXXX"; truncate $f, $total or die $!; close $f;
    my $b = eval { Data::CountingBloomFilter::Shared->new($p, 1000, 0.01) };
    ok(!$b, "new() refuses a foreign nonzero-magic file (no clobber)");
    like($@, qr/invalid/i, "  ... reporting an invalid file");
    undef $b; unlink $p;
}

# 3. No recovery for the wrong size: magic==0 but size != total still errors.
{
    open my $f, '>', $p or die $!; truncate $f, $total + 8 or die $!; close $f;
    my $b = eval { Data::CountingBloomFilter::Shared->new($p, 1000, 0.01) };
    ok(!$b, "new() refuses an uninitialized file of the wrong size");
    undef $b; unlink $p;
}

# 4. A valid file is attached, never re-initialized (its data survives).
{
    my $a = Data::CountingBloomFilter::Shared->new($p, 1000, 0.01); $a->add("keep"); undef $a;
    my $r = Data::CountingBloomFilter::Shared->new($p, 1000, 0.01);
    ok($r->contains("keep"), "reopening a valid file preserves its data");
    undef $r; unlink $p;
}

# 5. A magic==0 file of the right size but with NON-zero data (not a fresh
#    ftruncate) is NOT recovered -- recovery only re-inits a provably-empty file.
{
    open my $f, '>', $p or die $!; truncate $f, $total or die $!; close $f;
    open $f, '+<', $p or die $!; seek $f, $total - 1, 0; print $f "\x01"; close $f;
    my $b = eval { Data::CountingBloomFilter::Shared->new($p, 1000, 0.01) };
    ok(!$b, "new() refuses a magic==0 file that is not all-zero (no clobber of real data)");
    undef $b; unlink $p;
}

done_testing;
