use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Histogram::Shared;

# A creator killed between ftruncate() and header init leaves a full-size,
# all-zero (magic==0) file.  new() must recover it instead of bricking the path,
# but must never clobber a valid or foreign file.

my $dir = tempdir(CLEANUP => 1);
my $p   = "$dir/recover.hist";

# Learn the on-disk size for this geometry.
{ my $h = Data::Histogram::Shared->new($p, 1, 1_000_000, 3); }
my $total = -s $p;
unlink $p;

# 1. Recovery: an abandoned all-zero file of exactly $total bytes is re-initialized.
{
    open my $f, '>', $p or die $!; truncate $f, $total or die $!; close $f;
    is(-s $p, $total, "abandoned file is $total bytes (a killed creator's ftruncate)");
    my $h = eval { Data::Histogram::Shared->new($p, 1, 1_000_000, 3) };
    ok($h, "new() recovers an abandoned mid-init file instead of bricking") or diag $@;
  SKIP: {
        skip "no handle", 5 unless $h;
        is($h->total_count, 0, "recovered histogram starts empty (total_count 0)");
        is($h->count, 0, "recovered histogram starts empty (count alias 0)");
        $h->record(1234);
        is($h->count_at_value(1234), 1, "recovered histogram works (record/count_at_value)");
        is($h->count, 1, "count() (total_count alias) reflects the new record");
        cmp_ok($h->percentile(100), '>=', 1234, "percentile() reflects the new record");
    }
    undef $h; unlink $p;
}

# 2. No clobber: a file with nonzero (foreign) magic still errors.
{
    open my $f, '>', $p or die $!; print $f "XXXX"; truncate $f, $total or die $!; close $f;
    my $h = eval { Data::Histogram::Shared->new($p, 1, 1_000_000, 3) };
    ok(!$h, "new() refuses a foreign nonzero-magic file (no clobber)");
    like($@, qr/invalid/i, "  ... reporting an invalid file");
    undef $h; unlink $p;
}

# 3. No recovery for the wrong size: magic==0 but size != total still errors.
{
    open my $f, '>', $p or die $!; truncate $f, $total + 8 or die $!; close $f;
    my $h = eval { Data::Histogram::Shared->new($p, 1, 1_000_000, 3) };
    ok(!$h, "new() refuses an uninitialized file of the wrong size");
    undef $h; unlink $p;
}

# 4. A valid file is attached, never re-initialized (its data survives).
{
    my $a = Data::Histogram::Shared->new($p, 1, 1_000_000, 3); $a->record(555); undef $a;
    my $r = Data::Histogram::Shared->new($p, 1, 1_000_000, 3);
    is($r->total_count, 1, "reopening a valid file preserves its data (total_count)");
    is($r->count_at_value(555), 1, "reopening a valid file preserves its data (count_at_value)");
    undef $r; unlink $p;
}

# 5. A magic==0 file of the right size but with NON-zero data (not a fresh
#    ftruncate) is NOT recovered -- recovery only re-inits a provably-empty file.
{
    open my $f, '>', $p or die $!; truncate $f, $total or die $!; close $f;
    open $f, '+<', $p or die $!; seek $f, $total - 1, 0; print $f "\x01"; close $f;
    my $h = eval { Data::Histogram::Shared->new($p, 1, 1_000_000, 3) };
    ok(!$h, "new() refuses a magic==0 file that is not all-zero (no clobber of real data)");
    undef $h; unlink $p;
}

done_testing;
