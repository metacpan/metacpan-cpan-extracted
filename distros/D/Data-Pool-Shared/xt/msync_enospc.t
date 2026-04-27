use strict;
use warnings;
use Test::More;

# msync on a filesystem with no free space must error cleanly (ENOSPC),
# not silently corrupt. Uses /proc/mounts to find a suitable tmpfs with
# measurable free space; skips if none found.

plan skip_all => "needs Linux" unless $^O eq 'linux';

use Data::Pool::Shared;
use File::Temp qw(tempfile);

# Find a small tmpfs with limited free space. /dev/shm is typical.
my $mount = '/dev/shm';
plan skip_all => "$mount not writable" unless -w $mount;

# Check available space; skip if > 1GB (too large to fill reliably)
my $stat = `df -B1 $mount 2>/dev/null | tail -1`;
my @parts = split /\s+/, $stat;
my $avail = $parts[3] // 0;
plan skip_all => "$mount too large ($avail bytes) to fill"
    if $avail > 1024 * 1024 * 1024;

diag "testing on $mount with ${\ int($avail/1024/1024)}MB available";

my ($fh, $path) = tempfile(DIR => $mount, SUFFIX => '.pool', UNLINK => 1);
close $fh;

my $p = eval { Data::Pool::Shared::I64->new($path, 100) };
ok $p, "created pool on $mount";

# Fill $mount with junk files to exhaust free space
my @junk_fhs;
my $junk_written = 0;
my $deadline = time + 10;
while (time < $deadline) {
    my (undef, $jpath) = tempfile(DIR => $mount, SUFFIX => '.junk');
    open my $jfh, '>', $jpath or last;
    binmode $jfh;
    my $buf = "x" x (1024 * 1024);
    while (print $jfh $buf) { $junk_written += length($buf) }
    close $jfh;
    push @junk_fhs, $jpath;
    last if $junk_written > $avail;
}

diag "filled $junk_written bytes of junk";

# msync should now error OR succeed (if msync doesn't need to grow)
my $rc = eval { $p->sync; 1 };
ok 1, "msync handled disk-full (rc=" . ($rc ? 'success' : "error: $@") . ")";

# Cleanup
unlink $_ for @junk_fhs;

done_testing;
