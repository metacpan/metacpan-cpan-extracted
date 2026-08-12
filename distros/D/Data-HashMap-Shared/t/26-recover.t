use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::HashMap::Shared::II;

# A creator killed between ftruncate() and shm_init_header() leaves a full-size,
# all-zero (magic==0) file.  new() must recover it instead of bricking the path,
# and must never clobber a valid or foreign file.

my $dir = tempdir(CLEANUP => 1);
my $p   = "$dir/recover.hm";

{ my $m = Data::HashMap::Shared::II->new($p, 1000); }
my $total = -s $p;
unlink $p;

# 1. Recovery: an abandoned all-zero file of exactly $total bytes is re-initialized.
{
    open my $f, '>', $p or die $!; truncate $f, $total or die $!; close $f;
    is(-s $p, $total, "abandoned file is $total bytes");
    my $m = eval { Data::HashMap::Shared::II->new($p, 1000) };
    ok($m, "new() recovers an abandoned mid-init file") or diag $@;
  SKIP: {
        skip "no handle", 2 unless $m;
        ok(!defined $m->get(42), "recovered map starts empty");
        $m->put(42, 100); is($m->get(42), 100, "recovered map is usable");
    }
    undef $m; unlink $p;
}

# 2. No clobber: a file with nonzero (foreign) magic still errors.
{
    open my $f, '>', $p or die $!; print $f "XXXX"; truncate $f, $total or die $!; close $f;
    my $m = eval { Data::HashMap::Shared::II->new($p, 1000) };
    ok(!$m, "new() refuses a foreign nonzero-magic file (no clobber)");
    undef $m; unlink $p;
}

# 3. No recovery for the wrong size: magic==0 but size != total still errors.
{
    open my $f, '>', $p or die $!; truncate $f, $total + 8 or die $!; close $f;
    my $m = eval { Data::HashMap::Shared::II->new($p, 1000) };
    ok(!$m, "new() refuses an uninitialized file of the wrong size");
    undef $m; unlink $p;
}

# 4. A valid file is attached, never re-initialized (its data survives).
{
    my $a = Data::HashMap::Shared::II->new($p, 1000); $a->put(7, 99); undef $a;
    my $r = Data::HashMap::Shared::II->new($p, 1000);
    is($r->get(7), 99, "reopening a valid file preserves its data");
    undef $r; unlink $p;
}

# 5. A magic==0 file of the right size but with NON-zero data (not a fresh
#    ftruncate) is NOT recovered -- recovery only re-inits a provably-empty file.
{
    open my $zfh, '>', $p or die $!; truncate $zfh, $total or die $!; close $zfh;
    open $zfh, '+<', $p or die $!; seek $zfh, $total - 1, 0; print $zfh "\x01"; close $zfh;
    my $m = eval { Data::HashMap::Shared::II->new($p, 1000) };
    ok(!$m, "new() refuses a magic==0 file that is not all-zero (no clobber of real data)");
    undef $m; unlink $p;
}

done_testing;
