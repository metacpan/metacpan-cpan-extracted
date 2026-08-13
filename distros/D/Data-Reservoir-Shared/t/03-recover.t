use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Reservoir::Shared;

# A creator killed between ftruncate() and header init leaves a full-size,
# all-zero (magic==0) file.  new() must recover it instead of bricking the path,
# but must never clobber a valid or foreign file.

my $dir = tempdir(CLEANUP => 1);
my $p   = "$dir/recover.rsv";
my ($k, $item_size) = (10, 16);

# Learn the on-disk size for this geometry.
{ my $r = Data::Reservoir::Shared->new($p, $k, $item_size); }
my $total = -s $p;
unlink $p;

# 1. Recovery: an abandoned all-zero file of exactly $total bytes is re-initialized.
{
    open my $f, '>', $p or die $!; truncate $f, $total or die $!; close $f;
    is(-s $p, $total, "abandoned file is $total bytes (a killed creator's ftruncate)");
    my $r = eval { Data::Reservoir::Shared->new($p, $k, $item_size) };
    ok($r, "new() recovers an abandoned mid-init file instead of bricking") or diag $@;
  SKIP: {
        skip "no handle", 7 unless $r;
        # Recovered reservoir must be provably empty first (memset, not stale data).
        is($r->count, 0, "recovered reservoir starts empty (count)");
        is($r->seen,  0, "recovered reservoir starts empty (seen)");
        is_deeply([$r->sample], [], "recovered reservoir starts empty (sample)");
        # Then confirm it is fully usable: add a few samples and read them back.
        $r->add("item$_") for 1 .. 5;
        is($r->count, 5, "recovered reservoir usable: count after adding 5 items");
        is($r->seen,  5, "recovered reservoir usable: seen after adding 5 items");
        is($r->capacity, $k, "recovered reservoir has the right size (capacity)");
        is_deeply([sort $r->sample], [sort map { "item$_" } 1 .. 5],
            "recovered reservoir sample holds exactly what was added");
    }
    undef $r; unlink $p;
}

# 2. No clobber: a file with nonzero (foreign) magic still errors.
{
    open my $f, '>', $p or die $!; print $f "XXXX"; truncate $f, $total or die $!; close $f;
    my $r = eval { Data::Reservoir::Shared->new($p, $k, $item_size) };
    ok(!$r, "new() refuses a foreign nonzero-magic file (no clobber)");
    like($@, qr/invalid/i, "  ... reporting an invalid file");
    undef $r; unlink $p;
}

# 3. No recovery for the wrong size: magic==0 but size != total still errors.
{
    open my $f, '>', $p or die $!; truncate $f, $total + 8 or die $!; close $f;
    my $r = eval { Data::Reservoir::Shared->new($p, $k, $item_size) };
    ok(!$r, "new() refuses an uninitialized file of the wrong size");
    undef $r; unlink $p;
}

# 4. A valid file is attached, never re-initialized (its data survives).
{
    my $a = Data::Reservoir::Shared->new($p, $k, $item_size);
    $a->add("keep$_") for 1 .. 5;
    my @orig = sort $a->sample;
    my $seen_before = $a->seen;
    undef $a;
    my $r = Data::Reservoir::Shared->new($p, $k, $item_size);
    is($r->seen, $seen_before, "reopening a valid file preserves seen (not re-initialized)");
    is_deeply([sort $r->sample], \@orig, "reopening a valid file preserves its data");
    undef $r; unlink $p;
}
# 5. A magic==0 file of the right size but with NON-zero data (not a fresh
#    ftruncate) is NOT recovered -- recovery only re-inits a provably-empty file.
{
    open my $zfh, '>', $p or die $!; truncate $zfh, $total or die $!; close $zfh;
    open $zfh, '+<', $p or die $!; seek $zfh, $total - 1, 0; print $zfh "\x01"; close $zfh;
    my $r = eval { Data::Reservoir::Shared->new($p, $k, $item_size) };
    ok(!$r, "new() refuses a magic==0 file that is not all-zero (no clobber of real data)");
    undef $r; unlink $p;
}

done_testing;
