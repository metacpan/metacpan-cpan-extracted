use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::NDArray::Shared;

# A creator killed between ftruncate() and header init leaves a full-size,
# all-zero (magic==0) file.  new() must recover it instead of bricking the path,
# but must never clobber a valid or foreign file.

my $dir = tempdir(CLEANUP => 1);
my $p   = "$dir/recover.nda";

# Learn the on-disk size for this geometry (f64, 2x3 = 6 elements).
{ my $a = Data::NDArray::Shared->new($p, "f64", 2, 3); }
my $total = -s $p;
unlink $p;

# 1. Recovery: an abandoned all-zero file of exactly $total bytes is re-initialized.
{
    open my $f, '>', $p or die $!; truncate $f, $total or die $!; close $f;
    is(-s $p, $total, "abandoned file is $total bytes (a killed creator's ftruncate)");
    my $b = eval { Data::NDArray::Shared->new($p, "f64", 2, 3) };
    ok($b, "new() recovers an abandoned mid-init file instead of bricking") or diag $@;
  SKIP: {
        skip "no handle", 3 unless $b;
        is_deeply($b->to_list, [ (0) x 6 ], "recovered array starts zeroed");
        $b->set(1, 2, 42.5);
        is($b->get(1, 2), 42.5, "recovered array works (set/get round-trip)");
        is($b->get_flat(0), 0, "recovered array: untouched cell still 0");
    }
    undef $b; unlink $p;
}

# 2. No clobber: a file with nonzero (foreign) magic still errors.
{
    open my $f, '>', $p or die $!; print $f "XXXX"; truncate $f, $total or die $!; close $f;
    my $b = eval { Data::NDArray::Shared->new($p, "f64", 2, 3) };
    ok(!$b, "new() refuses a foreign nonzero-magic file (no clobber)");
    like($@, qr/invalid/i, "  ... reporting an invalid file");
    undef $b; unlink $p;
}

# 3. No recovery for the wrong size: magic==0 but size != total still errors.
{
    open my $f, '>', $p or die $!; truncate $f, $total + 8 or die $!; close $f;
    my $b = eval { Data::NDArray::Shared->new($p, "f64", 2, 3) };
    ok(!$b, "new() refuses an uninitialized file of the wrong size");
    undef $b; unlink $p;
}

# 4. A valid file is attached, never re-initialized (its data survives).
{
    my $a = Data::NDArray::Shared->new($p, "f64", 2, 3); $a->set(0, 1, 7.25); undef $a;
    my $r = Data::NDArray::Shared->new($p, "f64", 2, 3);
    is($r->get(0, 1), 7.25, "reopening a valid file preserves its data");
    undef $r; unlink $p;
}
# 5. A magic==0 file of the right size but with NON-zero data (not a fresh
#    ftruncate) is NOT recovered -- recovery only re-inits a provably-empty file.
{
    open my $zfh, '>', $p or die $!; truncate $zfh, $total or die $!; close $zfh;
    open $zfh, '+<', $p or die $!; seek $zfh, $total - 1, 0; print $zfh "\x01"; close $zfh;
    my $b = eval { Data::NDArray::Shared->new($p, "f64", 2, 3) };
    ok(!$b, "new() refuses a magic==0 file that is not all-zero (no clobber of real data)");
    undef $b; unlink $p;
}

done_testing;
