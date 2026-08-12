use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::HyperLogLog::Shared;

# A creator killed between ftruncate() and header init leaves a full-size,
# all-zero (magic==0) file.  new() must recover it instead of bricking the path,
# but must never clobber a valid or foreign file.

my $dir = tempdir(CLEANUP => 1);
my $p   = "$dir/recover.hll";

# Learn the on-disk size for this geometry.
{ my $h = Data::HyperLogLog::Shared->new($p, 10); }
my $total = -s $p;
unlink $p;

# 1. Recovery: an abandoned all-zero file of exactly $total bytes is re-initialized.
{
    open my $f, '>', $p or die $!; truncate $f, $total or die $!; close $f;
    is(-s $p, $total, "abandoned file is $total bytes (a killed creator's ftruncate)");
    my $h = eval { Data::HyperLogLog::Shared->new($p, 10) };
    ok($h, "new() recovers an abandoned mid-init file instead of bricking") or diag $@;
  SKIP: {
        skip "no handle", 4 unless $h;
        is($h->precision, 10, 'recovered estimator has the requested precision');
        is($h->count, 0, 'recovered estimator starts at ~0 (empty)');
        $h->add("x"); $h->add("y"); $h->add("z");
        cmp_ok($h->count, '>', 0, 'recovered estimator works (add bumps the estimate)');
        cmp_ok($h->count, '<=', 3, 'recovered estimator count is sane for 3 items');
    }
    undef $h; unlink $p;
}

# 2. No clobber: a file with nonzero (foreign) magic still errors.
{
    open my $f, '>', $p or die $!; print $f "XXXX"; truncate $f, $total or die $!; close $f;
    my $h = eval { Data::HyperLogLog::Shared->new($p, 10) };
    ok(!$h, "new() refuses a foreign nonzero-magic file (no clobber)");
    like($@, qr/invalid/i, "  ... reporting an invalid file");
    undef $h; unlink $p;
}

# 3. No recovery for the wrong size: magic==0 but size != total still errors.
{
    open my $f, '>', $p or die $!; truncate $f, $total + 8 or die $!; close $f;
    my $h = eval { Data::HyperLogLog::Shared->new($p, 10) };
    ok(!$h, "new() refuses an uninitialized file of the wrong size");
    undef $h; unlink $p;
}

# 4. A valid file is attached, never re-initialized (its data survives).
{
    my $a = Data::HyperLogLog::Shared->new($p, 10);
    $a->add($_) for 1 .. 50;
    my $before = $a->count;
    undef $a;
    my $r = Data::HyperLogLog::Shared->new($p, 10);
    is($r->count, $before, 'reopening a valid file preserves its data (not re-initialized)');
    undef $r; unlink $p;
}

# 5. A magic==0 file of the right size but with NON-zero data (not a fresh
#    ftruncate) is NOT recovered -- recovery only re-inits a provably-empty file.
{
    open my $f, '>', $p or die $!; truncate $f, $total or die $!; close $f;
    open $f, '+<', $p or die $!; seek $f, $total - 1, 0; print $f "\x01"; close $f;
    my $h = eval { Data::HyperLogLog::Shared->new($p, 10) };
    ok(!$h, "new() refuses a magic==0 file that is not all-zero (no clobber of real data)");
    undef $h; unlink $p;
}

done_testing;
