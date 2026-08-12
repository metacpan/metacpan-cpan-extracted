use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::DDSketch::Shared;

# A creator killed between ftruncate() and header init leaves a full-size,
# all-zero (magic==0) file.  new() must recover it instead of bricking the path,
# but must never clobber a valid or foreign file.

my $dir = tempdir(CLEANUP => 1);
my $p   = "$dir/recover.dd";

my $alpha       = 0.01;
my $num_buckets = 256;

# Learn the on-disk size for this geometry.
{ my $d = Data::DDSketch::Shared->new($p, $alpha, $num_buckets); }
my $total = -s $p;
unlink $p;

# 1. Recovery: an abandoned all-zero file of exactly $total bytes is re-initialized.
{
    open my $f, '>', $p or die $!; truncate $f, $total or die $!; close $f;
    is(-s $p, $total, "abandoned file is $total bytes (a killed creator's ftruncate)");
    my $d = eval { Data::DDSketch::Shared->new($p, $alpha, $num_buckets) };
    ok($d, "new() recovers an abandoned mid-init file instead of bricking") or diag $@;
  SKIP: {
        skip "no handle", 6 unless $d;
        is($d->count, 0, "recovered sketch starts empty (count==0, no stale data)");
        ok(!defined($d->quantile(0.5)), "recovered empty sketch has no quantile");
        ok(!defined($d->min), "recovered empty sketch has no min");
        ok(!defined($d->max), "recovered empty sketch has no max");
        $d->add($_) for (10, 20, 30);
        is($d->count, 3, "recovered sketch accepts add()");
        is($d->min, 10, "min after add on recovered sketch");
        is($d->max, 30, "max after add on recovered sketch");
        ok(defined($d->quantile(0.5)), "quantile reachable after recovery + add");
    }
    undef $d; unlink $p;
}

# 2. No clobber: a file with nonzero (foreign) magic still errors.
{
    open my $f, '>', $p or die $!; print $f "XXXX"; truncate $f, $total or die $!; close $f;
    my $d = eval { Data::DDSketch::Shared->new($p, $alpha, $num_buckets) };
    ok(!$d, "new() refuses a foreign nonzero-magic file (no clobber)");
    like($@, qr/invalid/i, "  ... reporting an invalid file");
    undef $d; unlink $p;
}

# 3. No recovery for the wrong size: magic==0 but size != total still errors.
{
    open my $f, '>', $p or die $!; truncate $f, $total + 8 or die $!; close $f;
    my $d = eval { Data::DDSketch::Shared->new($p, $alpha, $num_buckets) };
    ok(!$d, "new() refuses an uninitialized file of the wrong size");
    undef $d; unlink $p;
}

# 4. A valid file is attached, never re-initialized (its data survives).
{
    my $a = Data::DDSketch::Shared->new($p, $alpha, $num_buckets);
    $a->add($_) for (5, 15, 25);
    undef $a;
    my $r = Data::DDSketch::Shared->new($p, $alpha, $num_buckets);
    is($r->count, 3, "reopening a valid file preserves its data (count)");
    is($r->min, 5, "  ... min preserved");
    is($r->max, 25, "  ... max preserved");
    undef $r; unlink $p;
}

# 5. A magic==0 file of the right size but with NON-zero data (not a fresh
#    ftruncate) is NOT recovered -- recovery only re-inits a provably-empty file.
{
    open my $f, '>', $p or die $!; truncate $f, $total or die $!; close $f;
    open $f, '+<', $p or die $!; seek $f, $total - 1, 0; print $f "\x01"; close $f;
    my $d = eval { Data::DDSketch::Shared->new($p, $alpha, $num_buckets) };
    ok(!$d, "new() refuses a magic==0 file that is not all-zero (no clobber of real data)");
    undef $d; unlink $p;
}

done_testing;
