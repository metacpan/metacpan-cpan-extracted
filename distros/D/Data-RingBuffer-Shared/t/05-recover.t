use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::RingBuffer::Shared;

# A creator killed between ftruncate() and header init leaves a full-size,
# all-zero (magic==0) file.  new() must recover it instead of bricking the path,
# but must never clobber a valid or foreign file.

my $dir = tempdir(CLEANUP => 1);
my $p   = "$dir/recover.ring";

# Learn the on-disk size for this geometry.
{ my $r = Data::RingBuffer::Shared::Int->new($p, 10); }
my $total = -s $p;
unlink $p;

# 1. Recovery: an abandoned all-zero file of exactly $total bytes is re-initialized.
{
    open my $f, '>', $p or die $!; truncate $f, $total or die $!; close $f;
    is(-s $p, $total, "abandoned file is $total bytes (a killed creator's ftruncate)");
    my $r = eval { Data::RingBuffer::Shared::Int->new($p, 10) };
    ok($r, "new() recovers an abandoned mid-init file instead of bricking") or diag $@;
  SKIP: {
        skip "no handle", 3 unless $r;
        is($r->size, 0, "recovered ring starts empty");
        $r->write(42);
        is($r->latest, 42, "recovered ring works (write/latest)");
        is($r->size, 1, "recovered ring size updates after write");
    }
    undef $r; unlink $p;
}

# 2. No clobber: a file with nonzero (foreign) magic still errors.
{
    open my $f, '>', $p or die $!; print $f "XXXX"; truncate $f, $total or die $!; close $f;
    my $r = eval { Data::RingBuffer::Shared::Int->new($p, 10) };
    ok(!$r, "new() refuses a foreign nonzero-magic file (no clobber)");
    like($@, qr/invalid/i, "  ... reporting an invalid file");
    undef $r; unlink $p;
}

# 3. No recovery for the wrong size: magic==0 but size != total still errors.
{
    open my $f, '>', $p or die $!; truncate $f, $total + 8 or die $!; close $f;
    my $r = eval { Data::RingBuffer::Shared::Int->new($p, 10) };
    ok(!$r, "new() refuses an uninitialized file of the wrong size");
    undef $r; unlink $p;
}

# 4. A valid file is attached, never re-initialized (its data survives).
{
    my $a = Data::RingBuffer::Shared::Int->new($p, 10);
    $a->write(111); $a->write(222); undef $a;
    my $r = Data::RingBuffer::Shared::Int->new($p, 10);
    is($r->size, 2, "reopening a valid file preserves its data (size)");
    is($r->latest, 222, "reopening a valid file preserves its data (latest)");
    undef $r; unlink $p;
}
# 5. A magic==0 file of the right size but with NON-zero data (not a fresh
#    ftruncate) is NOT recovered -- recovery only re-inits a provably-empty file.
{
    open my $zfh, '>', $p or die $!; truncate $zfh, $total or die $!; close $zfh;
    open $zfh, '+<', $p or die $!; seek $zfh, $total - 1, 0; print $zfh "\x01"; close $zfh;
    my $r = eval { Data::RingBuffer::Shared::Int->new($p, 10) };
    ok(!$r, "new() refuses a magic==0 file that is not all-zero (no clobber of real data)");
    undef $r; unlink $p;
}

done_testing;
