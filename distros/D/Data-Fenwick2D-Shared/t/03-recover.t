use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Fenwick2D::Shared;

# A creator killed between ftruncate() and header init leaves a full-size,
# all-zero (magic==0) file.  new() must recover it instead of bricking the path,
# but must never clobber a valid or foreign file.

my $dir = tempdir(CLEANUP => 1);
my $p   = "$dir/recover.f2d";
my ($R, $C) = (8, 6);

# Learn the on-disk size for this geometry.
{ my $f = Data::Fenwick2D::Shared->new($p, $R, $C); }
my $total = -s $p;
unlink $p;

# 1. Recovery: an abandoned all-zero file of exactly $total bytes is re-initialized.
{
    open my $fh, '>', $p or die $!; truncate $fh, $total or die $!; close $fh;
    is(-s $p, $total, "abandoned file is $total bytes (a killed creator's ftruncate)");
    my $f = eval { Data::Fenwick2D::Shared->new($p, $R, $C) };
    ok($f, "new() recovers an abandoned mid-init file instead of bricking") or diag $@;
  SKIP: {
        skip "no handle", 7 unless $f;
        is($f->rows, $R, 'recovered tree has the requested rows');
        is($f->cols, $C, 'recovered tree has the requested cols');
        is($f->total, 0, 'recovered tree queries 0 everywhere (total)');
        is($f->point(4, 3), 0, 'recovered tree queries 0 everywhere (point)');
        is($f->prefix($R, $C), 0, 'recovered tree queries 0 everywhere (prefix)');
        $f->update(4, 3, 42);
        is($f->point(4, 3), 42, 'recovered tree usable: update+point');
        is($f->total, 42, 'recovered tree usable: update+total');
    }
    undef $f; unlink $p;
}

# 2. No clobber: a file with nonzero (foreign) magic still errors.
{
    open my $fh, '>', $p or die $!; print $fh "XXXX"; truncate $fh, $total or die $!; close $fh;
    my $f = eval { Data::Fenwick2D::Shared->new($p, $R, $C) };
    ok(!$f, "new() refuses a foreign nonzero-magic file (no clobber)");
    like($@, qr/invalid/i, "  ... reporting an invalid file");
    undef $f; unlink $p;
}

# 3. No recovery for the wrong size: magic==0 but size != total still errors.
{
    open my $fh, '>', $p or die $!; truncate $fh, $total + 8 or die $!; close $fh;
    my $f = eval { Data::Fenwick2D::Shared->new($p, $R, $C) };
    ok(!$f, "new() refuses an uninitialized file of the wrong size");
    undef $f; unlink $p;
}

# 4. A valid file is attached, never re-initialized (its data survives).
{
    my $a = Data::Fenwick2D::Shared->new($p, $R, $C); $a->update(2, 2, 99); undef $a;
    my $r = Data::Fenwick2D::Shared->new($p, $R, $C);
    is($r->point(2, 2), 99, 'reopening a valid file preserves its data');
    undef $r; unlink $p;
}

# 5. A magic==0 file of the right size but with NON-zero data (not a fresh
#    ftruncate) is NOT recovered -- recovery only re-inits a provably-empty file.
{
    open my $fh, '>', $p or die $!; truncate $fh, $total or die $!; close $fh;
    open $fh, '+<', $p or die $!; seek $fh, $total - 1, 0; print $fh "\x01"; close $fh;
    my $f = eval { Data::Fenwick2D::Shared->new($p, $R, $C) };
    ok(!$f, "new() refuses a magic==0 file that is not all-zero (no clobber of real data)");
    undef $f; unlink $p;
}

done_testing;
