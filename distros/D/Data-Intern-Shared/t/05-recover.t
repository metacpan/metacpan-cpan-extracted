use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Intern::Shared;

# A creator killed between ftruncate() and header init leaves a full-size,
# all-zero (magic==0) file.  new() must recover it instead of bricking the path,
# but must never clobber a valid or foreign file.

my $dir = tempdir(CLEANUP => 1);
my $p   = "$dir/recover.intern";

# Learn the on-disk size for this geometry.
{ my $in = Data::Intern::Shared->new($p, 100, 4096); }
my $total = -s $p;
unlink $p;

# 1. Recovery: an abandoned all-zero file of exactly $total bytes is re-initialized.
{
    open my $f, '>', $p or die $!; truncate $f, $total or die $!; close $f;
    is(-s $p, $total, "abandoned file is $total bytes (a killed creator's ftruncate)");
    my $in = eval { Data::Intern::Shared->new($p, 100, 4096) };
    ok($in, "new() recovers an abandoned mid-init file instead of bricking") or diag $@;
  SKIP: {
        skip "no handle", 4 unless $in;
        is($in->count, 0, "recovered table starts empty (no stale entries)");
        my $id = $in->intern("hello");
        ok(defined($id), "recovered table accepts an intern");
        is($in->string($id), "hello", "recovered table resolves the id back to the string");
        is($in->id_of("hello"), $id, "recovered table looks the string back up to the same id");
    }
    undef $in; unlink $p;
}

# 2. No clobber: a file with nonzero (foreign) magic still errors.
{
    open my $f, '>', $p or die $!; print $f "XXXX"; truncate $f, $total or die $!; close $f;
    my $in = eval { Data::Intern::Shared->new($p, 100, 4096) };
    ok(!$in, "new() refuses a foreign nonzero-magic file (no clobber)");
    like($@, qr/invalid/i, "  ... reporting an invalid file");
    undef $in; unlink $p;
}

# 3. No recovery for the wrong size: magic==0 but size != total still errors.
{
    open my $f, '>', $p or die $!; truncate $f, $total + 8 or die $!; close $f;
    my $in = eval { Data::Intern::Shared->new($p, 100, 4096) };
    ok(!$in, "new() refuses an uninitialized file of the wrong size");
    undef $in; unlink $p;
}

# 4. A valid file is attached, never re-initialized (its data survives).
{
    my $a = Data::Intern::Shared->new($p, 100, 4096);
    my $id = $a->intern("keep");
    undef $a;
    my $r = Data::Intern::Shared->new($p, 100, 4096);
    is($r->string($id), "keep", "reopening a valid file preserves its data");
    is($r->count, 1, "reopening a valid file preserves its count (not re-initialized)");
    undef $r; unlink $p;
}

# 5. A magic==0 file of the right size but with NON-zero data (not a fresh
#    ftruncate) is NOT recovered -- recovery only re-inits a provably-empty file.
{
    open my $f, '>', $p or die $!; truncate $f, $total or die $!; close $f;
    open $f, '+<', $p or die $!; seek $f, $total - 1, 0; print $f "\x01"; close $f;
    my $in = eval { Data::Intern::Shared->new($p, 100, 4096) };
    ok(!$in, "new() refuses a magic==0 file that is not all-zero (no clobber of real data)");
    undef $in; unlink $p;
}

done_testing;
