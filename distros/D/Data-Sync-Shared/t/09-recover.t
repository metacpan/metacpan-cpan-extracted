use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use Data::Sync::Shared;

# A creator killed between ftruncate() and header init (sync_create's is_new
# tail) leaves a full-size, all-zero (magic==0) file.  new() must recover it
# instead of bricking the path, but must never clobber a valid or foreign
# file.  Exercised via Semaphore, but the recovery lives in the single
# file-backed sync_create() shared by all five primitives.

my $path = tmpnam() . '.shm';
END { unlink $path if $path && -f $path }

# Learn the on-disk size for this geometry (Semaphore, max=3).
{ my $s = Data::Sync::Shared::Semaphore->new($path, 3); }
my $total = -s $path;
unlink $path;

# 1. Recovery: an abandoned all-zero file of exactly $total bytes is re-initialized.
{
    open my $f, '>', $path or die $!; truncate $f, $total or die $!; close $f;
    is(-s $path, $total, "abandoned file is $total bytes (a killed creator's ftruncate)");
    my $s = eval { Data::Sync::Shared::Semaphore->new($path, 3) };
    ok($s, "new() recovers an abandoned mid-init file instead of bricking") or diag $@;
  SKIP: {
        skip "no handle", 3 unless $s;
        is($s->max, 3, "recovered semaphore has the requested geometry");
        is($s->value, 3, "recovered semaphore starts fully available (freshly initialized)");
        ok($s->try_acquire, "recovered semaphore is usable (try_acquire succeeds)");
    }
    undef $s; unlink $path;
}

# 2. No clobber: a file with nonzero (foreign) magic still errors.
{
    open my $f, '>', $path or die $!; print $f "XXXX"; truncate $f, $total or die $!; close $f;
    my $s = eval { Data::Sync::Shared::Semaphore->new($path, 3) };
    ok(!$s, "new() refuses a foreign nonzero-magic file (no clobber)");
    like($@, qr/invalid or incompatible/, "  ... reporting an invalid file");
    undef $s; unlink $path;
}

# 3. No recovery for the wrong size: magic==0 but size != total still errors.
{
    open my $f, '>', $path or die $!; truncate $f, $total + 8 or die $!; close $f;
    my $s = eval { Data::Sync::Shared::Semaphore->new($path, 3) };
    ok(!$s, "new() refuses an uninitialized file of the wrong size");
    like($@, qr/invalid or incompatible/, "  ... reporting an invalid file");
    undef $s; unlink $path;
}

# 4. A valid file is attached, never re-initialized (its data survives).
{
    my $a = Data::Sync::Shared::Semaphore->new($path, 3);
    ok($a->try_acquire, "seed: acquire one permit (value 3 -> 2)");
    undef $a;
    my $r = Data::Sync::Shared::Semaphore->new($path, 3);
    is($r->value, 2, "reopening a valid file preserves its data (not re-initialized to 3)");
    undef $r; unlink $path;
}

# 5. A magic==0 file of the right size but with NON-zero data (not a fresh
#    ftruncate) is NOT recovered -- recovery only re-inits a provably-empty file.
{
    open my $zfh, '>', $path or die $!; truncate $zfh, $total or die $!; close $zfh;
    open $zfh, '+<', $path or die $!; seek $zfh, $total - 1, 0; print $zfh "\x01"; close $zfh;
    my $s = eval { Data::Sync::Shared::Semaphore->new($path, 3) };
    ok(!$s, "new() refuses a magic==0 file that is not all-zero (no clobber of real data)");
    undef $s; unlink $path;
}

done_testing;
