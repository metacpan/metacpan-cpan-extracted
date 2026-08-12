use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Buffer::Shared::I64;

# buf_create_map already re-initializes an uninitialized (magic==0) file, so a
# creator killed after ftruncate does not brick the path.  This test pins that
# recovery down AND the ownership guard added for the size>0 magic==0 case:
# recovery must never (re)initialize a foreign file.

my $dir = tempdir(CLEANUP => 1);
my $p   = "$dir/recover.i64";

# Learn the on-disk size for this geometry.
{ my $b = Data::Buffer::Shared::I64->new($p, 1024); }
my $total = -s $p;
unlink $p;

# 1. Recovery: an abandoned all-zero file of exactly $total bytes is re-initialized.
{
    open my $f, '>', $p or die $!; truncate $f, $total or die $!; close $f;
    is(-s $p, $total, "abandoned file is $total bytes");
    my $b = eval { Data::Buffer::Shared::I64->new($p, 1024) };
    ok($b, "new() recovers an abandoned mid-init file") or diag $@;
  SKIP: {
        skip "no handle", 2 unless $b;
        is($b->get(0), 0, "recovered buffer starts zeroed");
        $b->set(3, 42); is($b->get(3), 42, "recovered buffer is usable");
    }
    undef $b; unlink $p;
}

# 2. No clobber: a file with nonzero (foreign) magic still errors.
{
    open my $f, '>', $p or die $!; print $f "XXXX"; truncate $f, $total or die $!; close $f;
    my $b = eval { Data::Buffer::Shared::I64->new($p, 1024) };
    ok(!$b, "new() refuses a foreign nonzero-magic file (no clobber)");
    undef $b; unlink $p;
}

# 3. A magic==0 file smaller than the geometry is refused (never memset out of bounds).
{
    open my $f, '>', $p or die $!; truncate $f, $total - 8 or die $!; close $f;
    my $b = eval { Data::Buffer::Shared::I64->new($p, 1024) };
    ok(!$b, "new() refuses an uninitialized file that is too small");
    like($@, qr/too small/i, "  ... reporting it is too small");
    undef $b; unlink $p;
}

# 4. A valid file is attached, never re-initialized (its data survives).
{
    my $a = Data::Buffer::Shared::I64->new($p, 1024); $a->set(7, 99); undef $a;
    my $r = Data::Buffer::Shared::I64->new($p, 1024);
    is($r->get(7), 99, "reopening a valid file preserves its data");
    undef $r; unlink $p;
}

# 5. A magic==0 file of the right size but with NON-zero data (not a fresh
#    ftruncate) is NOT re-initialized -- only a provably-empty file is.
{
    open my $zfh, '>', $p or die $!; truncate $zfh, $total or die $!; close $zfh;
    open $zfh, '+<', $p or die $!; seek $zfh, $total - 1, 0; print $zfh "\x01"; close $zfh;
    my $b = eval { Data::Buffer::Shared::I64->new($p, 1024) };
    ok(!$b, "new() refuses a magic==0 file that is not all-zero (no clobber of real data)");
    undef $b; unlink $p;
}

done_testing;
