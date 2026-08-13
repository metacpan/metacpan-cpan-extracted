use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Log::Shared;

# A creator killed between ftruncate() and header init leaves a full-size,
# all-zero (magic==0) file.  new() must recover it instead of bricking the path,
# but must never clobber a valid or foreign file.

my $dir = tempdir(CLEANUP => 1);
my $p   = "$dir/recover.log";
my $data_size = 4096;

# Learn the on-disk size for this geometry.
{ my $l = Data::Log::Shared->new($p, $data_size); }
my $total = -s $p;
unlink $p;

# 1. Recovery: an abandoned all-zero file of exactly $total bytes is re-initialized.
{
    open my $f, '>', $p or die $!; truncate $f, $total or die $!; close $f;
    is(-s $p, $total, "abandoned file is $total bytes (a killed creator's ftruncate)");
    my $l = eval { Data::Log::Shared->new($p, $data_size) };
    ok($l, "new() recovers an abandoned mid-init file instead of bricking") or diag $@;
  SKIP: {
        skip "no handle", 3 unless $l;
        is($l->entry_count, 0, "recovered log starts empty (no stale entries)");
        my $off = $l->append("hello");
        ok(defined $off, "recovered log is writable (append succeeds)");
        my ($data, undef) = $l->read_entry($off);
        is($data, "hello", "recovered log round-trips a fresh append");
    }
    undef $l; unlink $p;
}

# 2. No clobber: a file with nonzero (foreign) magic still errors.
{
    open my $f, '>', $p or die $!; print $f "XXXX"; truncate $f, $total or die $!; close $f;
    my $l = eval { Data::Log::Shared->new($p, $data_size) };
    ok(!$l, "new() refuses a foreign nonzero-magic file (no clobber)");
    like($@, qr/magic/i, "  ... reporting a magic mismatch");
    undef $l; unlink $p;
}

# 3. No recovery for the wrong size: magic==0 but size != total still errors.
{
    open my $f, '>', $p or die $!; truncate $f, $total + 8 or die $!; close $f;
    my $l = eval { Data::Log::Shared->new($p, $data_size) };
    ok(!$l, "new() refuses an uninitialized file of the wrong size");
    undef $l; unlink $p;
}

# 4. A valid file is attached, never re-initialized (its data survives).
{
    my $a = Data::Log::Shared->new($p, $data_size); $a->append("keep"); undef $a;
    my $r = Data::Log::Shared->new($p, $data_size);
    is($r->entry_count, 1, "reopening a valid file preserves entry_count");
    my ($data, undef) = $r->read_entry(0);
    is($data, "keep", "reopening a valid file preserves its data");
    undef $r; unlink $p;
}
# 5. A magic==0 file of the right size but with NON-zero data (not a fresh
#    ftruncate) is NOT recovered -- recovery only re-inits a provably-empty file.
{
    open my $zfh, '>', $p or die $!; truncate $zfh, $total or die $!; close $zfh;
    open $zfh, '+<', $p or die $!; seek $zfh, $total - 1, 0; print $zfh "\x01"; close $zfh;
    my $l = eval { Data::Log::Shared->new($p, $data_size) };
    ok(!$l, "new() refuses a magic==0 file that is not all-zero (no clobber of real data)");
    undef $l; unlink $p;
}

done_testing;
