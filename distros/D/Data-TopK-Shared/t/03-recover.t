use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::TopK::Shared;

# A creator killed between ftruncate() and header init leaves a full-size,
# all-zero (magic==0) file.  new() must recover it instead of bricking the path,
# but must never clobber a valid or foreign file.

my $dir = tempdir(CLEANUP => 1);
my $p   = "$dir/recover.tk";

# Learn the on-disk size for this geometry.
{ my $w = Data::TopK::Shared->new($p, 50, 32); }
my $total = -s $p;
unlink $p;

# 1. Recovery: an abandoned all-zero file of exactly $total bytes is re-initialized.
{
    open my $f, '>', $p or die $!; truncate $f, $total or die $!; close $f;
    is(-s $p, $total, "abandoned file is $total bytes (a killed creator's ftruncate)");
    my $tk = eval { Data::TopK::Shared->new($p, 50, 32) };
    ok($tk, "new() recovers an abandoned mid-init file instead of bricking") or diag $@;
  SKIP: {
        skip "no handle", 5 unless $tk;
        is($tk->tracked, 0, "recovered table starts empty: tracked 0");
        is($tk->seen, 0, "recovered table starts empty: seen 0");
        is_deeply [$tk->top], [], "recovered table starts empty: top is empty";
        $tk->add("x") for 1 .. 3;
        is($tk->estimate("x"), 3, "recovered table works (add/estimate)");
        my @top = $tk->top(1);
        is($top[0]{key}, "x", "recovered table works (top)");
    }
    undef $tk; unlink $p;
}

# 2. No clobber: a file with nonzero (foreign) magic still errors.
{
    open my $f, '>', $p or die $!; print $f "XXXX"; truncate $f, $total or die $!; close $f;
    my $tk = eval { Data::TopK::Shared->new($p, 50, 32) };
    ok(!$tk, "new() refuses a foreign nonzero-magic file (no clobber)");
    like($@, qr/invalid/i, "  ... reporting an invalid file");
    undef $tk; unlink $p;
}

# 3. No recovery for the wrong size: magic==0 but size != total still errors.
{
    open my $f, '>', $p or die $!; truncate $f, $total + 8 or die $!; close $f;
    my $tk = eval { Data::TopK::Shared->new($p, 50, 32) };
    ok(!$tk, "new() refuses an uninitialized file of the wrong size");
    undef $tk; unlink $p;
}

# 4. A valid file is attached, never re-initialized (its data survives).
{
    my $a = Data::TopK::Shared->new($p, 50, 32); $a->add("keep") for 1 .. 5; undef $a;
    my $r = Data::TopK::Shared->new($p, 50, 32);
    is($r->estimate("keep"), 5, "reopening a valid file preserves its data");
    undef $r; unlink $p;
}
# 5. A magic==0 file of the right size but with NON-zero data (not a fresh
#    ftruncate) is NOT recovered -- recovery only re-inits a provably-empty file.
{
    open my $zfh, '>', $p or die $!; truncate $zfh, $total or die $!; close $zfh;
    open $zfh, '+<', $p or die $!; seek $zfh, $total - 1, 0; print $zfh "\x01"; close $zfh;
    my $tk = eval { Data::TopK::Shared->new($p, 50, 32) };
    ok(!$tk, "new() refuses a magic==0 file that is not all-zero (no clobber of real data)");
    undef $tk; unlink $p;
}

done_testing;
