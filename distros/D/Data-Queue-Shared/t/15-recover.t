use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Queue::Shared::Int;

# A creator killed between ftruncate() and queue_init_new_header() leaves a
# full-size, all-zero (magic==0) file.  new() must recover it instead of
# bricking the path, and must never clobber a valid or foreign file.

my $dir = tempdir(CLEANUP => 1);
my $p   = "$dir/recover.q";

{ my $q = Data::Queue::Shared::Int->new($p, 16); }
my $total = -s $p;
unlink $p;

# 1. Recovery: an abandoned all-zero file of exactly $total bytes is re-initialized.
{
    open my $f, '>', $p or die $!; truncate $f, $total or die $!; close $f;
    is(-s $p, $total, "abandoned file is $total bytes");
    my $q = eval { Data::Queue::Shared::Int->new($p, 16) };
    ok($q, "new() recovers an abandoned mid-init file") or diag $@;
  SKIP: {
        skip "no handle", 3 unless $q;
        ok($q->is_empty, "recovered queue starts empty");
        $q->push(42);
        is($q->size, 1, "recovered queue is usable (push)");
        is($q->pop, 42, "recovered queue is usable (pop)");
    }
    undef $q; unlink $p;
}

# 2. No clobber: a file with nonzero (foreign) magic still errors.
{
    open my $f, '>', $p or die $!; print $f "XXXX"; truncate $f, $total or die $!; close $f;
    my $q = eval { Data::Queue::Shared::Int->new($p, 16) };
    ok(!$q, "new() refuses a foreign nonzero-magic file (no clobber)");
    undef $q; unlink $p;
}

# 3. No recovery for the wrong size: magic==0 but size != total still errors.
{
    open my $f, '>', $p or die $!; truncate $f, $total + 8 or die $!; close $f;
    my $q = eval { Data::Queue::Shared::Int->new($p, 16) };
    ok(!$q, "new() refuses an uninitialized file of the wrong size");
    undef $q; unlink $p;
}

# 4. A valid file is attached, never re-initialized (its data survives).
{
    my $a = Data::Queue::Shared::Int->new($p, 16); $a->push(99); undef $a;
    my $r = Data::Queue::Shared::Int->new($p, 16);
    is($r->pop, 99, "reopening a valid file preserves its data");
    undef $r; unlink $p;
}
# 5. A magic==0 file of the right size but with NON-zero data (not a fresh
#    ftruncate) is NOT recovered -- recovery only re-inits a provably-empty file.
{
    open my $zfh, '>', $p or die $!; truncate $zfh, $total or die $!; close $zfh;
    open $zfh, '+<', $p or die $!; seek $zfh, $total - 1, 0; print $zfh "\x01"; close $zfh;
    my $q = eval { Data::Queue::Shared::Int->new($p, 16) };
    ok(!$q, "new() refuses a magic==0 file that is not all-zero (no clobber of real data)");
    undef $q; unlink $p;
}

done_testing;
