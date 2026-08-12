use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Fenwick::Shared;

# A creator killed between ftruncate() and header init leaves a full-size,
# all-zero (magic==0) file.  new() must recover it instead of bricking the path,
# but must never clobber a valid or foreign file.

my $dir = tempdir(CLEANUP => 1);
my $p   = "$dir/recover.fen";
my $n   = 50;

# Learn the on-disk size for this geometry.
{ my $f = Data::Fenwick::Shared->new($p, $n); }
my $total = -s $p;
unlink $p;

# 1. Recovery: an abandoned all-zero file of exactly $total bytes is re-initialized.
{
    open my $fh, '>', $p or die $!; truncate $fh, $total or die $!; close $fh;
    is(-s $p, $total, "abandoned file is $total bytes (a killed creator's ftruncate)");
    my $f = eval { Data::Fenwick::Shared->new($p, $n) };
    ok($f, "new() recovers an abandoned mid-init file instead of bricking") or diag $@;
  SKIP: {
        skip "no handle", 3 unless $f;
        is($f->total, 0, "recovered tree is all-zero (total == 0)");
        is($f->prefix($n), 0, "recovered tree prefix_sum is 0");
        $f->update(5, 7);
        is($f->prefix($n), 7, "recovered tree works (update + prefix_sum)");
    }
    undef $f; unlink $p;
}

# 2. No clobber: a file with nonzero (foreign) magic still errors.
{
    open my $fh, '>', $p or die $!; print $fh "XXXX"; truncate $fh, $total or die $!; close $fh;
    my $f = eval { Data::Fenwick::Shared->new($p, $n) };
    ok(!$f, "new() refuses a foreign nonzero-magic file (no clobber)");
    like($@, qr/invalid/i, "  ... reporting an invalid file");
    undef $f; unlink $p;
}

# 3. No recovery for the wrong size: magic==0 but size != total still errors.
{
    open my $fh, '>', $p or die $!; truncate $fh, $total + 8 or die $!; close $fh;
    my $f = eval { Data::Fenwick::Shared->new($p, $n) };
    ok(!$f, "new() refuses an uninitialized file of the wrong size");
    undef $f; unlink $p;
}

# 4. A valid file is attached, never re-initialized (its data survives).
{
    my $a = Data::Fenwick::Shared->new($p, $n); $a->update(9, 42); undef $a;
    my $r = Data::Fenwick::Shared->new($p, $n);
    is($r->point(9), 42, "reopening a valid file preserves its data");
    undef $r; unlink $p;
}
# 5. A magic==0 file of the right size but with NON-zero data (not a fresh
#    ftruncate) is NOT recovered -- recovery only re-inits a provably-empty file.
{
    open my $zfh, '>', $p or die $!; truncate $zfh, $total or die $!; close $zfh;
    open $zfh, '+<', $p or die $!; seek $zfh, $total - 1, 0; print $zfh "\x01"; close $zfh;
    my $f = eval { Data::Fenwick::Shared->new($p, $n) };
    ok(!$f, "new() refuses a magic==0 file that is not all-zero (no clobber of real data)");
    undef $f; unlink $p;
}

done_testing;
