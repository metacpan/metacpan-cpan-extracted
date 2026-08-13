use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::KDTree::Shared;

# A creator killed between ftruncate() and header init leaves a full-size,
# all-zero (magic==0) file.  new() must recover it instead of bricking the path,
# but must never clobber a valid or foreign file.

my $dir = tempdir(CLEANUP => 1);
my $p   = "$dir/recover.kdt";

# Learn the on-disk size for this geometry.
{ my $k = Data::KDTree::Shared->new($p, 2, 10); }
my $total = -s $p;
unlink $p;

# 1. Recovery: an abandoned all-zero file of exactly $total bytes is re-initialized.
{
    open my $f, '>', $p or die $!; truncate $f, $total or die $!; close $f;
    is(-s $p, $total, "abandoned file is $total bytes (a killed creator's ftruncate)");
    my $k = eval { Data::KDTree::Shared->new($p, 2, 10) };
    ok($k, "new() recovers an abandoned mid-init file instead of bricking") or diag $@;
  SKIP: {
        skip "no handle", 4 unless $k;
        is($k->count, 0, "recovered tree starts empty");
        ok(!defined($k->nearest([1, 2])), "recovered tree: nearest undef before any add");
        $k->add([1, 2], 42);
        is($k->count, 1, "recovered tree is usable (add)");
        is(+($k->nearest([1, 2]))->{id}, 42, "recovered tree is usable (nearest)");
    }
    undef $k; unlink $p;
}

# 2. No clobber: a file with nonzero (foreign) magic still errors.
{
    open my $f, '>', $p or die $!; print $f "XXXX"; truncate $f, $total or die $!; close $f;
    my $k = eval { Data::KDTree::Shared->new($p, 2, 10) };
    ok(!$k, "new() refuses a foreign nonzero-magic file (no clobber)");
    like($@, qr/invalid/i, "  ... reporting an invalid file");
    undef $k; unlink $p;
}

# 3. No recovery for the wrong size: magic==0 but size != total still errors.
{
    open my $f, '>', $p or die $!; truncate $f, $total + 8 or die $!; close $f;
    my $k = eval { Data::KDTree::Shared->new($p, 2, 10) };
    ok(!$k, "new() refuses an uninitialized file of the wrong size");
    undef $k; unlink $p;
}

# 4. A valid file is attached, never re-initialized (its data survives).
{
    my $a = Data::KDTree::Shared->new($p, 2, 10); $a->add([5, 5], 999); undef $a;
    my $r = Data::KDTree::Shared->new($p, 2, 10);
    is($r->count, 1, "reopening a valid file preserves its data (count)");
    is(+($r->nearest([5, 5]))->{id}, 999, "reopening a valid file preserves its data (nearest)");
    undef $r; unlink $p;
}
# 5. A magic==0 file of the right size but with NON-zero data (not a fresh
#    ftruncate) is NOT recovered -- recovery only re-inits a provably-empty file.
{
    open my $zfh, '>', $p or die $!; truncate $zfh, $total or die $!; close $zfh;
    open $zfh, '+<', $p or die $!; seek $zfh, $total - 1, 0; print $zfh "\x01"; close $zfh;
    my $k = eval { Data::KDTree::Shared->new($p, 2, 10) };
    ok(!$k, "new() refuses a magic==0 file that is not all-zero (no clobber of real data)");
    undef $k; unlink $p;
}

done_testing;
