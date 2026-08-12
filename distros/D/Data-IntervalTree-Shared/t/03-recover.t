use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::IntervalTree::Shared;

# A creator killed between ftruncate() and header init leaves a full-size,
# all-zero (magic==0) file.  new() must recover it instead of bricking the path,
# but must never clobber a valid or foreign file.

my $dir = tempdir(CLEANUP => 1);
my $p   = "$dir/recover.it";

# Learn the on-disk size for this geometry.
{ my $t = Data::IntervalTree::Shared->new($p, 100); }
my $total = -s $p;
unlink $p;

# 1. Recovery: an abandoned all-zero file of exactly $total bytes is re-initialized.
{
    open my $f, '>', $p or die $!; truncate $f, $total or die $!; close $f;
    is(-s $p, $total, "abandoned file is $total bytes (a killed creator's ftruncate)");
    my $t = eval { Data::IntervalTree::Shared->new($p, 100) };
    ok($t, "new() recovers an abandoned mid-init file instead of bricking") or diag $@;
  SKIP: {
        skip "no handle", 3 unless $t;
        is($t->count, 0, "recovered tree starts empty");
        $t->add(10, 20, 42);
        is($t->count, 1, "recovered tree is usable (add)");
        my ($hit) = $t->stab(15);
        is($hit->{id}, 42, "recovered tree is usable (add + stab readback)");
    }
    undef $t; unlink $p;
}

# 2. No clobber: a file with nonzero (foreign) magic still errors.
{
    open my $f, '>', $p or die $!; print $f "XXXX"; truncate $f, $total or die $!; close $f;
    my $t = eval { Data::IntervalTree::Shared->new($p, 100) };
    ok(!$t, "new() refuses a foreign nonzero-magic file (no clobber)");
    like($@, qr/invalid/i, "  ... reporting an invalid file");
    undef $t; unlink $p;
}

# 3. No recovery for the wrong size: magic==0 but size != total still errors.
{
    open my $f, '>', $p or die $!; truncate $f, $total + 8 or die $!; close $f;
    my $t = eval { Data::IntervalTree::Shared->new($p, 100) };
    ok(!$t, "new() refuses an uninitialized file of the wrong size");
    undef $t; unlink $p;
}

# 4. A valid file is attached, never re-initialized (its data survives).
{
    my $a = Data::IntervalTree::Shared->new($p, 100); $a->add(5, 9, 7); undef $a;
    my $r = Data::IntervalTree::Shared->new($p, 100);
    is($r->count, 1, "reopening a valid file preserves its data (count)");
    my ($hit) = $r->stab(7);
    is($hit->{id}, 7, "reopening a valid file preserves its data (stab)");
    undef $r; unlink $p;
}
# 5. A magic==0 file of the right size but with NON-zero data (not a fresh
#    ftruncate) is NOT recovered -- recovery only re-inits a provably-empty file.
{
    open my $zfh, '>', $p or die $!; truncate $zfh, $total or die $!; close $zfh;
    open $zfh, '+<', $p or die $!; seek $zfh, $total - 1, 0; print $zfh "\x01"; close $zfh;
    my $t = eval { Data::IntervalTree::Shared->new($p, 100) };
    ok(!$t, "new() refuses a magic==0 file that is not all-zero (no clobber of real data)");
    undef $t; unlink $p;
}

done_testing;
