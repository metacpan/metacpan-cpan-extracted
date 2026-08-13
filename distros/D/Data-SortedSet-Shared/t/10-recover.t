use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::SortedSet::Shared;

# A creator killed between ftruncate() and header init leaves a full-size,
# all-zero (magic==0) file.  new() must recover it instead of bricking the path,
# but must never clobber a valid or foreign file.

my $dir = tempdir(CLEANUP => 1);
my $p   = "$dir/recover.sset";
my $MAX = 100;

# Learn the on-disk size for this geometry.
{ my $s = Data::SortedSet::Shared->new($p, $MAX); }
my $total = -s $p;
unlink $p;

# 1. Recovery: an abandoned all-zero file of exactly $total bytes is re-initialized.
{
    open my $f, '>', $p or die $!; truncate $f, $total or die $!; close $f;
    is(-s $p, $total, "abandoned file is $total bytes (a killed creator's ftruncate)");
    my $s = eval { Data::SortedSet::Shared->new($p, $MAX) };
    ok($s, "new() recovers an abandoned mid-init file instead of bricking") or diag $@;
  SKIP: {
        skip "no handle", 4 unless $s;
        is($s->count, 0, "recovered set starts empty");
        $s->add(42, 3.5);
        is($s->count, 1, "add after recovery works");
        is($s->score(42), 3.5, "recovered set: score readback");
        is($s->rank(42), 0, "recovered set: rank readback");
    }
    undef $s; unlink $p;
}

# 2. No clobber: a file with nonzero (foreign) magic still errors.
{
    open my $f, '>', $p or die $!; print $f "XXXX"; truncate $f, $total or die $!; close $f;
    my $s = eval { Data::SortedSet::Shared->new($p, $MAX) };
    ok(!$s, "new() refuses a foreign nonzero-magic file (no clobber)");
    like($@, qr/invalid/i, "  ... reporting an invalid file");
    undef $s; unlink $p;
}

# 3. No recovery for the wrong size: magic==0 but size != total still errors.
{
    open my $f, '>', $p or die $!; truncate $f, $total + 8 or die $!; close $f;
    my $s = eval { Data::SortedSet::Shared->new($p, $MAX) };
    ok(!$s, "new() refuses an uninitialized file of the wrong size");
    undef $s; unlink $p;
}

# 4. A valid file is attached, never re-initialized (its data survives).
{
    my $a = Data::SortedSet::Shared->new($p, $MAX); $a->add(7, 1.25); undef $a;
    my $r = Data::SortedSet::Shared->new($p, $MAX);
    is($r->score(7), 1.25, "reopening a valid file preserves its data");
    undef $r; unlink $p;
}
# 5. A magic==0 file of the right size but with NON-zero data (not a fresh
#    ftruncate) is NOT recovered -- recovery only re-inits a provably-empty file.
{
    open my $zfh, '>', $p or die $!; truncate $zfh, $total or die $!; close $zfh;
    open $zfh, '+<', $p or die $!; seek $zfh, $total - 1, 0; print $zfh "\x01"; close $zfh;
    my $s = eval { Data::SortedSet::Shared->new($p, $MAX) };
    ok(!$s, "new() refuses a magic==0 file that is not all-zero (no clobber of real data)");
    undef $s; unlink $p;
}

done_testing;
