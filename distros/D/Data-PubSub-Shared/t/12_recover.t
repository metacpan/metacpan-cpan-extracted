use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::PubSub::Shared;

# A creator killed between ftruncate() and header init leaves a full-size,
# all-zero (magic==0) file.  new() must recover it instead of bricking the path,
# but must never clobber a valid or foreign file.

my $dir = tempdir(CLEANUP => 1);
my $p   = "$dir/recover.ps";

# Learn the on-disk size for this geometry.
{ my $b = Data::PubSub::Shared::Int->new($p, 64); }
my $total = -s $p;
unlink $p;

# 1. Recovery: an abandoned all-zero file of exactly $total bytes is re-initialized.
{
    open my $f, '>', $p or die $!; truncate $f, $total or die $!; close $f;
    is(-s $p, $total, "abandoned file is $total bytes (a killed creator's ftruncate)");
    my $b = eval { Data::PubSub::Shared::Int->new($p, 64) };
    ok($b, "new() recovers an abandoned mid-init file instead of bricking") or diag $@;
  SKIP: {
        skip "no handle", 3 unless $b;
        is($b->write_pos, 0, "recovered pubsub starts empty (write_pos 0)");
        $b->publish(42);
        my $sub = $b->subscribe_all;
        is($sub->poll, 42,    "recovered pubsub works (publish/poll)");
        is($sub->poll, undef, "recovered pubsub has no stale messages beyond what we published");
    }
    undef $b; unlink $p;
}

# 2. No clobber: a file with nonzero (foreign) magic still errors.
{
    open my $f, '>', $p or die $!; print $f "XXXX"; truncate $f, $total or die $!; close $f;
    my $b = eval { Data::PubSub::Shared::Int->new($p, 64) };
    ok(!$b, "new() refuses a foreign nonzero-magic file (no clobber)");
    like($@, qr/invalid/i, "  ... reporting an invalid file");
    undef $b; unlink $p;
}

# 3. No recovery for the wrong size: magic==0 but size != total still errors.
{
    open my $f, '>', $p or die $!; truncate $f, $total + 8 or die $!; close $f;
    my $b = eval { Data::PubSub::Shared::Int->new($p, 64) };
    ok(!$b, "new() refuses an uninitialized file of the wrong size");
    undef $b; unlink $p;
}

# 4. A valid file is attached, never re-initialized (its data survives).
{
    my $a = Data::PubSub::Shared::Int->new($p, 64);
    $a->publish(99);
    undef $a;
    my $r = Data::PubSub::Shared::Int->new($p, 64);
    my $sub = $r->subscribe_all;
    is($sub->poll, 99, "reopening a valid file preserves its data");
    undef $r; unlink $p;
}
# 5. A magic==0 file of the right size but with NON-zero data (not a fresh
#    ftruncate) is NOT recovered -- recovery only re-inits a provably-empty file.
{
    open my $zfh, '>', $p or die $!; truncate $zfh, $total or die $!; close $zfh;
    open $zfh, '+<', $p or die $!; seek $zfh, $total - 1, 0; print $zfh "\x01"; close $zfh;
    my $b = eval { Data::PubSub::Shared::Int->new($p, 64) };
    ok(!$b, "new() refuses a magic==0 file that is not all-zero (no clobber of real data)");
    undef $b; unlink $p;
}

done_testing;
