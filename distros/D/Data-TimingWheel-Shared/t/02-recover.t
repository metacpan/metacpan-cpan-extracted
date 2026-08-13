use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::TimingWheel::Shared;

# A creator killed between ftruncate() and header init leaves a full-size,
# all-zero (magic==0) file.  new() must recover it instead of bricking the path,
# but must never clobber a valid or foreign file.

my $dir = tempdir(CLEANUP => 1);
my $p   = "$dir/recover.tw";

# Learn the on-disk size for this geometry.
{ my $w = Data::TimingWheel::Shared->new($p, 64, 100); }
my $total = -s $p;
unlink $p;

# 1. Recovery: an abandoned all-zero file of exactly $total bytes is re-initialized.
{
    open my $f, '>', $p or die $!; truncate $f, $total or die $!; close $f;
    is(-s $p, $total, "abandoned file is $total bytes (a killed creator's ftruncate)");
    my $w = eval { Data::TimingWheel::Shared->new($p, 64, 100) };
    ok($w, "new() recovers an abandoned mid-init file instead of bricking") or diag $@;
  SKIP: {
        skip "no handle", 3 unless $w;
        is($w->count, 0, "recovered wheel starts empty (no stale timers)");
        $w->add(3, 999);
        is_deeply([$w->advance(3)], [999], "recovered wheel is usable (add/advance)");
        is($w->count, 0, "fired timer no longer pending");
    }
    undef $w; unlink $p;
}

# 2. No clobber: a file with nonzero (foreign) magic still errors.
{
    open my $f, '>', $p or die $!; print $f "XXXX"; truncate $f, $total or die $!; close $f;
    my $w = eval { Data::TimingWheel::Shared->new($p, 64, 100) };
    ok(!$w, "new() refuses a foreign nonzero-magic file (no clobber)");
    like($@, qr/invalid/i, "  ... reporting an invalid file");
    undef $w; unlink $p;
}

# 3. No recovery for the wrong size: magic==0 but size != total still errors.
{
    open my $f, '>', $p or die $!; truncate $f, $total + 8 or die $!; close $f;
    my $w = eval { Data::TimingWheel::Shared->new($p, 64, 100) };
    ok(!$w, "new() refuses an uninitialized file of the wrong size");
    undef $w; unlink $p;
}

# 4. A valid file is attached, never re-initialized (its data survives).
{
    my $a = Data::TimingWheel::Shared->new($p, 64, 100);
    $a->add(50, 1234);
    $a->sync;
    undef $a;
    my $r = Data::TimingWheel::Shared->new($p, 1, 1);   # geometry args ignored on reopen
    is($r->count, 1, "reopening a valid file preserves pending timers");
    my @fired;
    push @fired, $r->advance(1) for 1 .. 50;
    is_deeply(\@fired, [1234], "reopened wheel's timer still fires at its original tick");
    undef $r; unlink $p;
}
# 5. A magic==0 file of the right size but with NON-zero data (not a fresh
#    ftruncate) is NOT recovered -- recovery only re-inits a provably-empty file.
{
    open my $zfh, '>', $p or die $!; truncate $zfh, $total or die $!; close $zfh;
    open $zfh, '+<', $p or die $!; seek $zfh, $total - 1, 0; print $zfh "\x01"; close $zfh;
    my $w = eval { Data::TimingWheel::Shared->new($p, 64, 100) };
    ok(!$w, "new() refuses a magic==0 file that is not all-zero (no clobber of real data)");
    undef $w; unlink $p;
}

done_testing;
