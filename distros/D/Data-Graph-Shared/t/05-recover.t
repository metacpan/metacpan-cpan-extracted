use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Graph::Shared;

# A creator killed between ftruncate() and header init leaves a full-size,
# all-zero (magic==0) file.  new() must recover it instead of bricking the path,
# but must never clobber a valid or foreign file.

my $dir = tempdir(CLEANUP => 1);
my $p   = "$dir/recover.graph";

# Learn the on-disk size for this geometry.
{ my $g = Data::Graph::Shared->new($p, 10, 20); }
my $total = -s $p;
unlink $p;

# 1. Recovery: an abandoned all-zero file of exactly $total bytes is re-initialized.
{
    open my $f, '>', $p or die $!; truncate $f, $total or die $!; close $f;
    is(-s $p, $total, "abandoned file is $total bytes (a killed creator's ftruncate)");
    my $g = eval { Data::Graph::Shared->new($p, 10, 20) };
    ok($g, "new() recovers an abandoned mid-init file instead of bricking") or diag $@;
  SKIP: {
        skip "no handle", 4 unless $g;
        is($g->node_count, 0, "recovered graph starts empty (no stale nodes)");
        my $a = $g->add_node(111);
        my $b = $g->add_node(222);
        ok(defined $a && defined $b, "recovered graph accepts add_node");
        ok($g->add_edge($a, $b, 5), "recovered graph accepts add_edge");
        ok($g->has_node($a), "recovered graph works (add_node/has_node)");
    }
    undef $g; unlink $p;
}

# 2. No clobber: a file with nonzero (foreign) magic still errors.
{
    open my $f, '>', $p or die $!; print $f "XXXX"; truncate $f, $total or die $!; close $f;
    my $g = eval { Data::Graph::Shared->new($p, 10, 20) };
    ok(!$g, "new() refuses a foreign nonzero-magic file (no clobber)");
    like($@, qr/invalid/i, "  ... reporting an invalid file");
    undef $g; unlink $p;
}

# 3. No recovery for the wrong size: magic==0 but size != total still errors.
{
    open my $f, '>', $p or die $!; truncate $f, $total + 8 or die $!; close $f;
    my $g = eval { Data::Graph::Shared->new($p, 10, 20) };
    ok(!$g, "new() refuses an uninitialized file of the wrong size");
    undef $g; unlink $p;
}

# 4. A valid file is attached, never re-initialized (its data survives).
{
    my $a = Data::Graph::Shared->new($p, 10, 20);
    my $x = $a->add_node(42);
    my $y = $a->add_node(43);
    $a->add_edge($x, $y, 7);
    undef $a;
    my $r = Data::Graph::Shared->new($p, 10, 20);
    is($r->node_count, 2, "reopening a valid file preserves node_count");
    is($r->edge_count, 1, "reopening a valid file preserves edge_count");
    ok($r->has_node($x), "reopening a valid file preserves data");
    undef $r; unlink $p;
}
# 5. A magic==0 file of the right size but with NON-zero data (not a fresh
#    ftruncate) is NOT recovered -- recovery only re-inits a provably-empty file.
{
    open my $zfh, '>', $p or die $!; truncate $zfh, $total or die $!; close $zfh;
    open $zfh, '+<', $p or die $!; seek $zfh, $total - 1, 0; print $zfh "\x01"; close $zfh;
    my $g = eval { Data::Graph::Shared->new($p, 10, 20) };
    ok(!$g, "new() refuses a magic==0 file that is not all-zero (no clobber of real data)");
    undef $g; unlink $p;
}

done_testing;
